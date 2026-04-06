const { PrismaClient } = require('@prisma/client');
const { NotFoundError, ValidationError } = require('../utils/errors');
const notificationsService = require('./notifications.service');

const prisma = new PrismaClient();

const SESSION_TYPES = ['En_ligne', 'Présentiel', 'Hybride'];
const SESSION_STATUSES = ['Planifiée', 'En cours', 'Terminée', 'Annulée'];

class TrainingSessionsService {
  _extractPayload(body = {}) {
    if (body && typeof body === 'object' && body.data && typeof body.data === 'object') {
      return body.data;
    }
    return body;
  }

  _toInt(value) {
    if (value === undefined || value === null || value === '') return null;
    const parsed = parseInt(String(value), 10);
    return Number.isNaN(parsed) ? null : parsed;
  }

  _toIntArray(value) {
    if (!Array.isArray(value)) return [];
    return value
      .map((item) => this._toInt(item))
      .filter((item) => item !== null);
  }

  _parseId(rawId) {
    const id = this._toInt(rawId);
    if (!id || id <= 0) {
      throw new ValidationError('ID session invalide');
    }
    return id;
  }

  _parseDate(value) {
    if (value === undefined || value === null || value === '') return null;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      throw new ValidationError('Date invalide');
    }
    return date;
  }

  _normalizeType(value) {
    const normalized = String(value ?? '').trim();
    if (!normalized) return 'En_ligne';
    if (SESSION_TYPES.includes(normalized)) return normalized;
    return 'En_ligne';
  }

  _normalizeStatus(value) {
    const normalized = String(value ?? '').trim();
    if (!normalized) return 'Planifiée';
    if (SESSION_STATUSES.includes(normalized)) return normalized;
    return 'Planifiée';
  }

  _extractFilters(query = {}) {
    const instructorId = this._toInt(
      query?.['filters[instructor][id][$eq]'] ?? query?.filters?.instructor?.id?.$eq
    );
    const instructorRolesRaw = String(
      query?.['filters[instructor][role][$in]'] ?? query?.filters?.instructor?.role?.$in ?? ''
    ).trim();
    const instructorRoles = instructorRolesRaw
      ? instructorRolesRaw.split(',').map((role) => role.trim()).filter(Boolean)
      : [];
    const attendeeId = this._toInt(
      query?.['filters[attendees][id][$eq]'] ?? query?.filters?.attendees?.id?.$eq
    );
    const statusContains = String(
      query?.['filters[mystatus][$containsi]'] ?? query?.filters?.mystatus?.$containsi ?? ''
    ).trim();

    const sortRaw = String(query?.sort ?? '').trim().toLowerCase();
    const startDateSort = sortRaw.includes('start_datetime')
      ? (sortRaw.endsWith(':asc') ? 'asc' : 'desc')
      : null;

    return { instructorId, instructorRoles, attendeeId, statusContains, startDateSort };
  }

  _mapParticipant(user) {
    return {
      id: user.id,
      documentId: String(user.id),
      firstname: user.username || '',
      lastname: '',
      email: user.email || '',
    };
  }

  _mapCourse(course) {
    if (!course) return null;
    return {
      id: course.id,
      documentId: String(course.id),
      title: course.title,
    };
  }

  _mapSession(record) {
    return {
      id: record.id,
      documentId: String(record.id),
      title: record.title,
      course: this._mapCourse(record.course),
      courseAssociated: record.courseId,
      instructor: record.instructor
        ? {
            id: record.instructor.id,
            documentId: String(record.instructor.id),
            username: record.instructor.username,
            email: record.instructor.email,
            role: record.instructor.role,
          }
        : null,
      type: record.type || 'En_ligne',
      max_participants: record.maxParticipants ?? 10,
      start_datetime: record.startDate ? record.startDate.toISOString() : null,
      end_datetime: record.endDate ? record.endDate.toISOString() : null,
      meeting_url: record.meetingUrl || null,
      mystatus: record.mystatus || 'Planifiée',
      notes: record.notes ?? record.description ?? null,
      attendees: Array.isArray(record.attendees)
        ? record.attendees.map((row) => this._mapParticipant(row.user))
        : [],
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    };
  }

  _toCollection(records) {
    const data = records.map((record) => this._mapSession(record));
    return {
      data,
      meta: {
        pagination: {
          page: 1,
          pageSize: data.length,
          pageCount: 1,
          total: data.length,
        },
      },
    };
  }

  _toItem(record) {
    return { data: this._mapSession(record) };
  }

  _buildInclude() {
    return {
      instructor: {
        select: {
          id: true,
          username: true,
          email: true,
          role: true,
        },
      },
      course: {
        select: {
          id: true,
          title: true,
        },
      },
      attendees: {
        include: {
          user: {
            select: {
              id: true,
              username: true,
              email: true,
            },
          },
        },
      },
    };
  }

  async getSessions(query = {}) {
    const { instructorId, instructorRoles, attendeeId, statusContains, startDateSort } = this._extractFilters(query);

    const where = {};
    if (instructorId) {
      where.instructorId = instructorId;
    }

    if (instructorRoles.length) {
      where.instructor = {
        role: {
          in: instructorRoles,
        },
      };
    }

    if (attendeeId) {
      where.attendees = {
        some: {
          userId: attendeeId,
        },
      };
    }

    if (statusContains) {
      where.mystatus = {
        contains: statusContains,
      };
    }

    const records = await prisma.trainingSession.findMany({
      where,
      include: this._buildInclude(),
      orderBy: startDateSort
        ? { startDate: startDateSort }
        : { createdAt: 'desc' },
    });

    return this._toCollection(records);
  }

  async getSessionById(rawId) {
    const id = this._parseId(rawId);

    const record = await prisma.trainingSession.findUnique({
      where: { id },
      include: this._buildInclude(),
    });

    if (!record) {
      throw new NotFoundError('Session non trouvée');
    }

    return this._toItem(record);
  }

  async createSession(body, context = {}) {
    const payload = this._extractPayload(body);

    const title = String(payload.title || '').trim();
    if (!title) {
      throw new ValidationError('Titre session requis');
    }

    const courseId = this._toInt(payload.course ?? payload.courseAssociated);
    const startDate = this._parseDate(payload.start_datetime ?? payload.startDate);
    const endDate = this._parseDate(payload.end_datetime ?? payload.endDate);

    if (startDate && endDate && endDate < startDate) {
      throw new ValidationError('La date de fin doit être postérieure à la date de début');
    }

    const attendeeIds = this._toIntArray(payload.attendees);

    const created = await prisma.trainingSession.create({
      data: {
        title,
        courseId,
        type: this._normalizeType(payload.type),
        maxParticipants: this._toInt(payload.max_participants ?? payload.maxParticipants) ?? 10,
        startDate,
        endDate,
        meetingUrl: payload.meeting_url ? String(payload.meeting_url).trim() : null,
        mystatus: this._normalizeStatus(payload.mystatus ?? payload.status),
        notes: payload.notes ? String(payload.notes).trim() : null,
        description: payload.notes ? String(payload.notes).trim() : null,
        instructorId: this._toInt(payload.instructor) ?? context.userId ?? null,
        attendees: attendeeIds.length
          ? {
              create: attendeeIds.map((userId) => ({
                user: { connect: { id: userId } },
              })),
            }
          : undefined,
      },
      include: this._buildInclude(),
    });

    if (created.mystatus === 'En cours') {
      try {
        await notificationsService.notifyTrainingSessionStarted(created.id);
      } catch (error) {
        console.error('Failed to send training session start notification:', error.message);
      }
    }

    return this._toItem(created);
  }

  async updateSession(rawId, body) {
    const id = this._parseId(rawId);
    const payload = this._extractPayload(body);

    const existing = await prisma.trainingSession.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Session non trouvée');
    }

    const updateData = {};

    if (payload.title !== undefined) {
      const title = String(payload.title || '').trim();
      if (!title) {
        throw new ValidationError('Titre session requis');
      }
      updateData.title = title;
    }

    if (payload.course !== undefined || payload.courseAssociated !== undefined) {
      updateData.courseId = this._toInt(payload.course ?? payload.courseAssociated);
    }

    if (payload.type !== undefined) {
      updateData.type = this._normalizeType(payload.type);
    }

    if (payload.max_participants !== undefined || payload.maxParticipants !== undefined) {
      const max = this._toInt(payload.max_participants ?? payload.maxParticipants);
      updateData.maxParticipants = max && max > 0 ? max : 10;
    }

    if (payload.start_datetime !== undefined || payload.startDate !== undefined) {
      updateData.startDate = this._parseDate(payload.start_datetime ?? payload.startDate);
    }

    if (payload.end_datetime !== undefined || payload.endDate !== undefined) {
      updateData.endDate = this._parseDate(payload.end_datetime ?? payload.endDate);
    }

    if (payload.mystatus !== undefined || payload.status !== undefined) {
      updateData.mystatus = this._normalizeStatus(payload.mystatus ?? payload.status);
    }

    if (payload.meeting_url !== undefined || payload.meetingLink !== undefined) {
      const urlValue = payload.meeting_url ?? payload.meetingLink;
      updateData.meetingUrl = urlValue ? String(urlValue).trim() : null;
    }

    if (payload.notes !== undefined) {
      updateData.notes = payload.notes ? String(payload.notes).trim() : null;
      updateData.description = payload.notes ? String(payload.notes).trim() : null;
    }

    const attendeeIds = payload.attendees !== undefined ? this._toIntArray(payload.attendees) : null;

    const updated = await prisma.trainingSession.update({
      where: { id },
      data: {
        ...updateData,
        attendees: attendeeIds !== null
          ? {
              deleteMany: {},
              create: attendeeIds.map((userId) => ({
                user: { connect: { id: userId } },
              })),
            }
          : undefined,
      },
      include: this._buildInclude(),
    });

    if (existing.mystatus !== 'En cours' && updated.mystatus === 'En cours') {
      try {
        await notificationsService.notifyTrainingSessionStarted(updated.id);
      } catch (error) {
        console.error('Failed to send training session start notification:', error.message);
      }
    }

    return this._toItem(updated);
  }

  async deleteSession(rawId) {
    const id = this._parseId(rawId);

    const existing = await prisma.trainingSession.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Session non trouvée');
    }

    await prisma.trainingSession.delete({
      where: { id },
    });

    return { data: { id, deleted: true } };
  }
}

module.exports = new TrainingSessionsService();
