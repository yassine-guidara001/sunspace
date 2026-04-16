const { PrismaClient } = require('@prisma/client');
const { ValidationError, NotFoundError } = require('../utils/errors');
const notificationsService = require('./notifications.service');

const prisma = new PrismaClient();

class ReservationsService {
  _isWithinOpeningHours(date) {
    if (!(date instanceof Date)) return false;
    const minutes = date.getHours() * 60 + date.getMinutes();
    return minutes >= 9 * 60 && minutes <= 18 * 60;
  }

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

  _toFloat(value) {
    if (value === undefined || value === null || value === '') return null;
    const parsed = parseFloat(String(value));
    return Number.isNaN(parsed) ? null : parsed;
  }

  _parseDate(value) {
    if (value === undefined || value === null || value === '') return null;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return null;
    return date;
  }

  _mapStatusForResponse(status) {
    const raw = String(status || 'PENDING').toUpperCase();
    if (raw === 'CONFIRMED') return 'Confirmée';
    if (raw === 'REJECTED') return 'Rejetée';
    if (raw === 'CANCELLED') return 'Annulée';
    if (raw === 'COMPLETED') return 'Terminée';
    return 'En_attente';
  }

  _mapStatusToEnum(value) {
    const raw = String(value || '').trim().toLowerCase();
    if (raw.includes('confirm')) return 'CONFIRMED';
    if (raw.includes('rejet') || raw.includes('reject')) return 'REJECTED';
    if (raw.includes('annul') || raw.includes('cancel')) return 'CANCELLED';
    if (raw.includes('termin') || raw.includes('complete')) return 'COMPLETED';
    return 'PENDING';
  }

  _statusLabel(status) {
    return this._mapStatusForResponse(status).replace('_', ' ');
  }

  _mapReservation(record) {
    return {
      id: record.id,
      documentId: String(record.id),
      user: record.user
        ? {
            id: record.user.id,
            documentId: String(record.user.id),
            username: record.user.username,
            email: record.user.email,
          }
        : null,
      space: record.space
        ? {
            id: record.space.id,
            documentId: String(record.space.id),
            name: record.space.name,
            type: record.space.type,
            location: record.space.location,
          }
        : null,
      start_datetime: record.startDateTime ? record.startDateTime.toISOString() : null,
      end_datetime: record.endDateTime ? record.endDateTime.toISOString() : null,
      mystatus: this._mapStatusForResponse(record.status),
      status: record.status,
      organizer_name: record.organizerName || '',
      organizer_phone: record.organizerPhone || '',
      attendees: record.attendees ?? 1,
      is_all_day: Boolean(record.isAllDay),
      total_amount: record.totalAmount ?? 0,
      payment_method: record.paymentMethod || '',
      payment_status: record.paymentStatus || '',
      notes: record.notes || null,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    };
  }

  _buildWhere(query = {}) {
    const where = {};

    const userDocId = String(
      query?.['filters[user][documentId][$eq]'] ?? query?.filters?.user?.documentId?.$eq ?? ''
    ).trim();
    const userIdByDoc = this._toInt(userDocId);
    if (userIdByDoc) {
      where.userId = userIdByDoc;
    }

    const spaceId = this._toInt(
      query?.['filters[space][id][$eq]'] ?? query?.filters?.space?.id?.$eq
    );
    if (spaceId) {
      where.spaceId = spaceId;
    }

    const containsDate = String(
      query?.['filters[start_datetime][$contains]'] ?? query?.filters?.start_datetime?.$contains ?? ''
    ).trim();
    if (containsDate) {
      const start = new Date(`${containsDate}T00:00:00.000Z`);
      const end = new Date(`${containsDate}T23:59:59.999Z`);
      if (!Number.isNaN(start.getTime()) && !Number.isNaN(end.getTime())) {
        where.startDateTime = {
          gte: start,
          lte: end,
        };
      }
    }

    return where;
  }

  async getAll(query = {}) {
    const where = this._buildWhere(query);

    const records = await prisma.reservation.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true,
          },
        },
        space: {
          select: {
            id: true,
            name: true,
            type: true,
            location: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });

    return {
      data: records.map((record) => this._mapReservation(record)),
      meta: {
        pagination: {
          page: 1,
          pageSize: records.length,
          pageCount: 1,
          total: records.length,
        },
      },
    };
  }

  async create(body, context = {}) {
    const payload = this._extractPayload(body);

    const userId = context.userId;
    if (!userId) {
      throw new ValidationError('Utilisateur non authentifié');
    }

    // Try to find space by numeric ID or documentId string
    let spaceId = this._toInt(payload.space);
    let space = null;

    if (spaceId) {
      space = await prisma.space.findUnique({
        where: { id: spaceId },
        select: { id: true },
      });
    } else {
      // If not numeric, try to find by documentId
      const spaceDocId = String(payload.space || '').trim();
      if (spaceDocId) {
        space = await prisma.space.findFirst({
          where: { id: this._toInt(spaceDocId) },
          select: { id: true },
        });
      }
    }

    if (!space) {
      throw new ValidationError('Espace invalide');
    }
    spaceId = space.id;

    const startDateTime = this._parseDate(payload.start_datetime ?? payload.startDateTime);
    const endDateTime = this._parseDate(payload.end_datetime ?? payload.endDateTime);

    if (!startDateTime || !endDateTime) {
      throw new ValidationError('Date de réservation invalide');
    }

    if (endDateTime <= startDateTime) {
      throw new ValidationError('La fin doit être après le début');
    }

    if (!this._isWithinOpeningHours(startDateTime) || !this._isWithinOpeningHours(endDateTime)) {
      throw new ValidationError('Cet espace est ouvert uniquement de 09:00 à 18:00');
    }

    const overlappingReservation = await prisma.reservation.findFirst({
      where: {
        spaceId,
        status: {
          in: ['PENDING', 'CONFIRMED'],
        },
        startDateTime: {
          lt: endDateTime,
        },
        endDateTime: {
          gt: startDateTime,
        },
      },
      select: {
        id: true,
      },
    });

    if (overlappingReservation) {
      throw new ValidationError('Espace indisponible sur ce créneau. Choisissez une autre heure');
    }

    const row = await prisma.reservation.create({
      data: {
        userId,
        spaceId,
        startDateTime,
        endDateTime,
        status: this._mapStatusToEnum(payload.mystatus ?? payload.status),
        notes: payload.notes ? String(payload.notes) : null,
        organizerName: payload.organizer_name ? String(payload.organizer_name) : null,
        organizerPhone: payload.organizer_phone ? String(payload.organizer_phone) : null,
        attendees: this._toInt(payload.attendees) ?? 1,
        isAllDay: Boolean(payload.is_all_day),
        totalAmount: this._toFloat(payload.total_amount) ?? 0,
        paymentMethod: payload.payment_method ? String(payload.payment_method) : null,
        paymentStatus: payload.payment_status ? String(payload.payment_status) : null,
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true,
          },
        },
        space: {
          select: {
            id: true,
            name: true,
            type: true,
            location: true,
          },
        },
      },
    });

    return { data: this._mapReservation(row) };
  }

  async update(rawId, body) {
    const id = this._toInt(rawId);
    if (!id || id <= 0) {
      throw new ValidationError('ID réservation invalide');
    }

    const payload = this._extractPayload(body);

    const existing = await prisma.reservation.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Réservation non trouvée');
    }

    const data = {};
    const changes = {};

    if (payload.mystatus !== undefined || payload.status !== undefined) {
      data.status = this._mapStatusToEnum(payload.mystatus ?? payload.status);
      if (data.status !== existing.status) {
        changes.statut = `${this._statusLabel(existing.status)} -> ${this._statusLabel(data.status)}`;
      }
    }

    if (payload.notes !== undefined) {
      data.notes = payload.notes ? String(payload.notes) : null;
      if ((existing.notes || null) !== data.notes) {
        changes.notes = data.notes || 'Aucune';
      }
    }

    const row = await prisma.reservation.update({
      where: { id },
      data,
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true,
          },
        },
        space: {
          select: {
            id: true,
            name: true,
            type: true,
            location: true,
          },
        },
      },
    });

    const shouldEnsureConfirmationNotification =
      data.status === 'CONFIRMED' || (existing.status === 'CONFIRMED' && data.status === undefined);

    if (shouldEnsureConfirmationNotification) {
      // Keep reservation update resilient even if notification delivery fails.
      try {
        const existingConfirmation = await prisma.notification.findFirst({
          where: {
            reservationId: id,
            type: 'RESERVATION_CONFIRMATION',
          },
          select: { id: true },
        });

        if (!existingConfirmation) {
          await notificationsService.notifyReservationConfirmation(id);
        }
      } catch (error) {
        console.error('Failed to send reservation confirmation notification:', error.message);
      }
    }

    if (data.status === 'CANCELLED' && existing.status !== 'CANCELLED') {
      try {
        await notificationsService.notifyReservationCancelled(id, 'Mise à jour de statut');
      } catch (error) {
        console.error('Failed to send reservation cancellation notification:', error.message);
      }
    } else if (Object.keys(changes).length > 0) {
      try {
        await notificationsService.notifyReservationModified(id, changes);
      } catch (error) {
        console.error('Failed to send reservation modified notification:', error.message);
      }
    }

    return { data: this._mapReservation(row) };
  }

  async remove(rawId) {
    const id = this._toInt(rawId);
    if (!id || id <= 0) {
      throw new ValidationError('ID réservation invalide');
    }

    const existing = await prisma.reservation.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Réservation non trouvée');
    }

    try {
      await notificationsService.notifyReservationCancelled(id, 'Réservation supprimée');
    } catch (error) {
      console.error('Failed to send reservation cancellation notification:', error.message);
    }

    await prisma.reservation.delete({ where: { id } });

    return { data: { id, deleted: true } };
  }
}

module.exports = new ReservationsService();
