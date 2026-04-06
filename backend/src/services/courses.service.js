const { PrismaClient } = require('@prisma/client');
const { NotFoundError, ConflictError, ValidationError } = require('../utils/errors');
const notificationsService = require('./notifications.service');

const prisma = new PrismaClient();

const COURSE_LEVELS = ['Débutant', 'Intermédiaire', 'Avancé'];
const COURSE_STATUSES = ['Brouillon', 'Publié'];

class CoursesService {
  _extractPayload(body = {}) {
    if (body && typeof body === 'object' && body.data && typeof body.data === 'object') {
      return body.data;
    }
    return body;
  }

  _parseId(rawId) {
    const id = parseInt(String(rawId), 10);
    if (Number.isNaN(id) || id <= 0) {
      throw new ValidationError('ID cours invalide');
    }
    return id;
  }

  _normalizeLevel(level) {
    const value = String(level ?? '').trim();
    return COURSE_LEVELS.includes(value) ? value : null;
  }

  _normalizeStatus(status) {
    const value = String(status ?? '').trim();
    return COURSE_STATUSES.includes(value) ? value : null;
  }

  _toNumber(value) {
    if (value === undefined || value === null || value === '') return 0;
    const parsed = parseFloat(value);
    if (Number.isNaN(parsed) || parsed < 0) {
      throw new ValidationError('Prix invalide');
    }
    return parsed;
  }

  _toInt(value) {
    if (value === undefined || value === null || value === '') return null;
    const parsed = parseInt(String(value), 10);
    return Number.isNaN(parsed) ? null : parsed;
  }

  _extractFilters(query = {}) {
    const idFromFlat = query?.['filters[id][$eq]'];
    const idFromNested = query?.filters?.id?.$eq;
    const id = this._toInt(idFromFlat ?? idFromNested);
    const instructorIdFromFlat =
      query?.['filters[instructor][id][$eq]'] ?? query?.['filters[instructorId][$eq]'];
    const instructorIdFromNested =
      query?.filters?.instructor?.id?.$eq ?? query?.filters?.instructorId?.$eq;
    const instructorId = this._toInt(instructorIdFromFlat ?? instructorIdFromNested);
    return { id, instructorId };
  }

  _mapCourse(course) {
    return {
      id: course.id,
      documentId: String(course.id),
      title: course.title,
      description: course.description || '',
      level: course.level,
      price: course.price ?? 0,
      status: course.status,
      mystatus: course.status,
      createdAt: course.createdAt,
      updatedAt: course.updatedAt,
    };
  }

  _toCollection(courses) {
    const data = courses.map((course) => this._mapCourse(course));
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

  _toItem(course) {
    return { data: this._mapCourse(course) };
  }

  async getAllCourses(query = {}) {
    const { id, instructorId } = this._extractFilters(query);

    const where = {};
    if (id !== null) {
      where.id = id;
    }

    if (instructorId !== null) {
      where.instructorId = instructorId;
    }

    const courses = await prisma.course.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });

    return this._toCollection(courses);
  }

  async getCourseById(rawId) {
    const id = this._parseId(rawId);

    const course = await prisma.course.findUnique({
      where: { id },
    });

    if (!course) {
      throw new NotFoundError('Cours non trouvé');
    }

    return this._toItem(course);
  }

  async createCourse(body, context = {}) {
    const payload = this._extractPayload(body);

    const title = String(payload.title || '').trim();
    if (!title) {
      throw new ValidationError('Titre du cours requis');
    }

    const level = this._normalizeLevel(payload.level ?? 'Débutant');
    if (!level) {
      throw new ValidationError('Niveau invalide');
    }

    const status = this._normalizeStatus(payload.status ?? payload.mystatus ?? 'Brouillon');
    if (!status) {
      throw new ValidationError('Statut invalide');
    }

    const duplicate = await prisma.course.findFirst({
      where: { title },
    });

    if (duplicate) {
      throw new ConflictError('Un cours avec ce titre existe déjà');
    }

    const course = await prisma.course.create({
      data: {
        title,
        description: payload.description ? String(payload.description).trim() : null,
        level,
        price: this._toNumber(payload.price),
        status,
        instructorId: context.userId || null,
      },
    });

    if (course.status === 'Publié') {
      try {
        await notificationsService.notifyNewCourseAvailable(course.id);
      } catch (error) {
        console.error('Failed to send new course notification:', error.message);
      }
    }

    return this._toItem(course);
  }

  async updateCourse(rawId, body) {
    const id = this._parseId(rawId);
    const payload = this._extractPayload(body);

    const existing = await prisma.course.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundError('Cours non trouvé');
    }

    const updateData = {};

    if (payload.title !== undefined) {
      const title = String(payload.title).trim();
      if (!title) {
        throw new ValidationError('Titre du cours requis');
      }

      if (title !== existing.title) {
        const duplicate = await prisma.course.findFirst({
          where: {
            title,
            NOT: { id },
          },
        });

        if (duplicate) {
          throw new ConflictError('Un cours avec ce titre existe déjà');
        }
      }

      updateData.title = title;
    }

    if (payload.description !== undefined) {
      updateData.description = payload.description ? String(payload.description).trim() : null;
    }

    if (payload.level !== undefined) {
      const level = this._normalizeLevel(payload.level);
      if (!level) {
        throw new ValidationError('Niveau invalide');
      }
      updateData.level = level;
    }

    if (payload.price !== undefined) {
      updateData.price = this._toNumber(payload.price);
    }

    if (payload.status !== undefined || payload.mystatus !== undefined) {
      const status = this._normalizeStatus(payload.status ?? payload.mystatus);
      if (!status) {
        throw new ValidationError('Statut invalide');
      }
      updateData.status = status;
    }

    const updated = await prisma.course.update({
      where: { id },
      data: updateData,
    });

    if (existing.status !== 'Publié' && updated.status === 'Publié') {
      try {
        await notificationsService.notifyNewCourseAvailable(updated.id);
      } catch (error) {
        console.error('Failed to send new course notification:', error.message);
      }
    }

    return this._toItem(updated);
  }

  async deleteCourse(rawId) {
    const id = this._parseId(rawId);

    const existing = await prisma.course.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundError('Cours non trouvé');
    }

    await prisma.course.delete({
      where: { id },
    });

    return { data: { id, deleted: true } };
  }
}

module.exports = new CoursesService();
