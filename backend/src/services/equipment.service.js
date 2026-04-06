const { PrismaClient } = require('@prisma/client');
const { NotFoundError, ValidationError } = require('../utils/errors');

const prisma = new PrismaClient();

class EquipmentService {
  _extractPayload(body = {}) {
    if (body && typeof body === 'object' && body.data && typeof body.data === 'object') {
      return body.data;
    }
    return body;
  }

  _parseDate(value) {
    if (value === undefined || value === null || value === '') return null;
    if (value instanceof Date) return value;

    const raw = String(value).trim();
    if (!raw) return null;

    if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) {
      const date = new Date(`${raw}T00:00:00.000Z`);
      return Number.isNaN(date.getTime()) ? null : date;
    }

    const frMatch = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(raw);
    if (frMatch) {
      const [, dd, mm, yyyy] = frMatch;
      const date = new Date(`${yyyy}-${mm}-${dd}T00:00:00.000Z`);
      return Number.isNaN(date.getTime()) ? null : date;
    }

    const parsed = new Date(raw);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }

  _toNumber(value) {
    if (value === undefined || value === null || value === '') return null;
    const parsed = parseFloat(value);
    return Number.isNaN(parsed) ? null : parsed;
  }

  _normalizeStatus(value) {
    const status = (value || 'Disponible').toString().trim();
    if (!status) return 'Disponible';
    return status;
  }

  _isAvailableFromStatus(status) {
    const normalized = status.toLowerCase();
    return !normalized.includes('panne') && !normalized.includes('maintenance') && !normalized.includes('indisponible');
  }

  _toStrapiItem(record) {
    const spaces = Array.isArray(record.spaces)
      ? record.spaces
          .map((relation) => relation.space)
          .filter(Boolean)
          .map((space) => ({ id: space.id, name: space.name }))
      : [];

    const toIsoDateOnly = (dateValue) => {
      if (!dateValue) return '';
      const iso = new Date(dateValue).toISOString();
      return iso.slice(0, 10);
    };

    return {
      id: record.id,
      documentId: String(record.id),
      name: record.name || '',
      type: record.type || '',
      mystatus: record.mystatus || 'Disponible',
      serial_number: record.serialNumber || '',
      purchase_date: toIsoDateOnly(record.purchaseDate),
      purchase_price: record.purchasePrice ?? 0,
      price_per_day: record.pricePerDay ?? 0,
      warranty_expiry: toIsoDateOnly(record.warrantyExpiry),
      description: record.description || '',
      notes: record.notes || '',
      spaces,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    };
  }

  _parseId(rawId) {
    const id = parseInt(String(rawId), 10);
    if (Number.isNaN(id) || id <= 0) {
      throw new ValidationError('ID équipement invalide');
    }
    return id;
  }

  _extractStatusFilter(query) {
    if (!query || typeof query !== 'object') return null;
    return (
      query['filters[mystatus][$eq]'] ||
      query?.filters?.mystatus?.$eq ||
      query?.filters?.mystatus?.eq ||
      null
    );
  }

  _extractSort(query) {
    const rawSort = query?.sort;
    const sortValue = Array.isArray(rawSort) ? rawSort[0] : rawSort;
    if (!sortValue || typeof sortValue !== 'string') {
      return { createdAt: 'desc' };
    }

    const [fieldRaw, directionRaw] = sortValue.split(':');
    const fieldMap = {
      createdAt: 'createdAt',
      updatedAt: 'updatedAt',
      name: 'name',
      price_per_day: 'pricePerDay',
      purchase_price: 'purchasePrice',
      mystatus: 'mystatus',
    };

    const field = fieldMap[fieldRaw] || 'createdAt';
    const direction = String(directionRaw || 'desc').toLowerCase() === 'asc' ? 'asc' : 'desc';

    return { [field]: direction };
  }

  _extractPagination(query) {
    const page = parseInt(query?.['pagination[page]'] || query?.pagination?.page || '1', 10);
    const pageSize = parseInt(query?.['pagination[pageSize]'] || query?.pagination?.pageSize || '100', 10);

    const safePage = Number.isNaN(page) || page < 1 ? 1 : page;
    const safePageSize = Number.isNaN(pageSize) || pageSize < 1 ? 100 : Math.min(pageSize, 200);

    return {
      page: safePage,
      pageSize: safePageSize,
      skip: (safePage - 1) * safePageSize,
      take: safePageSize,
    };
  }

  async getAllEquipments(query = {}) {
    const statusFilter = this._extractStatusFilter(query);
    const where = statusFilter
      ? { mystatus: { equals: String(statusFilter) } }
      : undefined;

    const { page, pageSize, skip, take } = this._extractPagination(query);
    const orderBy = this._extractSort(query);

    const [total, records] = await Promise.all([
      prisma.equipment.count({ where }),
      prisma.equipment.findMany({
        where,
        skip,
        take,
        orderBy,
        include: {
          spaces: {
            include: {
              space: {
                select: { id: true, name: true },
              },
            },
          },
        },
      }),
    ]);

    return {
      data: records.map((record) => this._toStrapiItem(record)),
      meta: {
        pagination: {
          page,
          pageSize,
          pageCount: Math.max(1, Math.ceil(total / pageSize)),
          total,
        },
      },
    };
  }

  async getEquipmentById(rawId) {
    const id = this._parseId(rawId);

    const record = await prisma.equipment.findUnique({
      where: { id },
      include: {
        spaces: {
          include: {
            space: {
              select: { id: true, name: true },
            },
          },
        },
      },
    });

    if (!record) {
      throw new NotFoundError('Équipement non trouvé');
    }

    return { data: this._toStrapiItem(record) };
  }

  async createEquipment(rawBody) {
    const payload = this._extractPayload(rawBody);

    if (!payload.name || String(payload.name).trim() === '') {
      throw new ValidationError('Nom de l\'équipement requis');
    }

    const status = this._normalizeStatus(payload.mystatus);
    const serialNumber = payload.serial_number ? String(payload.serial_number).trim() : null;

    const parsedSpaceIds = Array.isArray(payload.spaceIds)
      ? payload.spaceIds.map((id) => parseInt(String(id), 10)).filter((id) => !Number.isNaN(id) && id > 0)
      : [];

    const created = await prisma.equipment.create({
      data: {
        name: String(payload.name).trim(),
        type: payload.type ? String(payload.type).trim() : null,
        mystatus: status,
        serialNumber,
        purchaseDate: this._parseDate(payload.purchase_date),
        purchasePrice: this._toNumber(payload.purchase_price),
        pricePerDay: this._toNumber(payload.price_per_day),
        warrantyExpiry: this._parseDate(payload.warranty_expiry),
        description: payload.description ? String(payload.description) : null,
        notes: payload.notes ? String(payload.notes) : null,
        quantity: payload.quantity ? parseInt(String(payload.quantity), 10) || 1 : 1,
        available: this._isAvailableFromStatus(status),
        imageUrl: payload.imageUrl ? String(payload.imageUrl) : null,
        spaces: parsedSpaceIds.length
          ? {
              create: parsedSpaceIds.map((spaceId) => ({
                space: { connect: { id: spaceId } },
              })),
            }
          : undefined,
      },
      include: {
        spaces: {
          include: {
            space: {
              select: { id: true, name: true },
            },
          },
        },
      },
    });

    return { data: this._toStrapiItem(created) };
  }

  async updateEquipment(rawId, rawBody) {
    const id = this._parseId(rawId);
    const payload = this._extractPayload(rawBody);

    const existing = await prisma.equipment.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Équipement non trouvé');
    }

    const status = payload.mystatus !== undefined
      ? this._normalizeStatus(payload.mystatus)
      : existing.mystatus;

    const updateData = {
      name: payload.name !== undefined ? String(payload.name).trim() : undefined,
      type: payload.type !== undefined ? (payload.type ? String(payload.type).trim() : null) : undefined,
      mystatus: status,
      serialNumber: payload.serial_number !== undefined
        ? (payload.serial_number ? String(payload.serial_number).trim() : null)
        : undefined,
      purchaseDate: payload.purchase_date !== undefined ? this._parseDate(payload.purchase_date) : undefined,
      purchasePrice: payload.purchase_price !== undefined ? this._toNumber(payload.purchase_price) : undefined,
      pricePerDay: payload.price_per_day !== undefined ? this._toNumber(payload.price_per_day) : undefined,
      warrantyExpiry: payload.warranty_expiry !== undefined ? this._parseDate(payload.warranty_expiry) : undefined,
      description: payload.description !== undefined ? (payload.description ? String(payload.description) : null) : undefined,
      notes: payload.notes !== undefined ? (payload.notes ? String(payload.notes) : null) : undefined,
      quantity: payload.quantity !== undefined ? (parseInt(String(payload.quantity), 10) || 1) : undefined,
      available: this._isAvailableFromStatus(status),
      imageUrl: payload.imageUrl !== undefined ? (payload.imageUrl ? String(payload.imageUrl) : null) : undefined,
    };

    const parsedSpaceIds = Array.isArray(payload.spaceIds)
      ? payload.spaceIds.map((spaceId) => parseInt(String(spaceId), 10)).filter((spaceId) => !Number.isNaN(spaceId) && spaceId > 0)
      : null;

    await prisma.$transaction(async (tx) => {
      await tx.equipment.update({
        where: { id },
        data: updateData,
      });

      if (parsedSpaceIds !== null) {
        await tx.spaceEquipment.deleteMany({ where: { equipmentId: id } });

        if (parsedSpaceIds.length) {
          await tx.spaceEquipment.createMany({
            data: parsedSpaceIds.map((spaceId) => ({
              equipmentId: id,
              spaceId,
              quantity: 1,
            })),
            skipDuplicates: true,
          });
        }
      }
    });

    return this.getEquipmentById(id);
  }

  async deleteEquipment(rawId) {
    const id = this._parseId(rawId);

    const existing = await prisma.equipment.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Équipement non trouvé');
    }

    await prisma.equipment.delete({ where: { id } });
    return { data: { id, deleted: true } };
  }
}

module.exports = new EquipmentService();
