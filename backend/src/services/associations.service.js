const { PrismaClient } = require('@prisma/client');
const { NotFoundError, ValidationError, ConflictError } = require('../utils/errors');

const prisma = new PrismaClient();

class AssociationsService {
  _extractPayload(body = {}) {
    if (body && typeof body === 'object' && body.data && typeof body.data === 'object') {
      return body.data;
    }
    return body;
  }

  _parseId(rawId) {
    const id = parseInt(String(rawId), 10);
    if (Number.isNaN(id) || id <= 0) {
      throw new ValidationError('ID association invalide');
    }
    return id;
  }

  _toNumber(value) {
    if (value === undefined || value === null || value === '') return null;
    const parsed = parseFloat(value);
    return Number.isNaN(parsed) ? null : parsed;
  }

  _toInt(value) {
    if (value === undefined || value === null || value === '') return null;
    const parsed = parseInt(String(value), 10);
    return Number.isNaN(parsed) ? null : parsed;
  }

  _toBool(value) {
    if (typeof value === 'boolean') return value;
    const normalized = String(value ?? '').trim().toLowerCase();
    return normalized === 'true' || normalized === '1' || normalized === 'yes';
  }

  _mapUser(user) {
    if (!user) return null;
    return {
      id: user.id,
      username: user.username,
      email: user.email,
      role: { name: user.role || 'USER' },
      blocked: user.blocked,
      confirmed: user.confirmed,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  _mapAssociation(record) {
    const members = Array.isArray(record.members)
      ? record.members
          .map((entry) => entry.user)
          .filter(Boolean)
          .map((user) => this._mapUser(user))
      : [];

    return {
      id: record.id,
      documentId: String(record.id),
      name: record.name,
      description: record.description || '',
      email: record.email || '',
      phone: record.phone || '',
      website: record.website || '',
      admin: this._mapUser(record.admin),
      members,
      budget: record.budget ?? 0,
      currency: record.currency || 'TND',
      verified: Boolean(record.verified),
      logoUrl: record.logoUrl || '',
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    };
  }

  _toStrapiCollection(items) {
    return {
      data: items.map((item) => this._mapAssociation(item)),
      meta: {
        pagination: {
          page: 1,
          pageSize: items.length,
          pageCount: 1,
          total: items.length,
        },
      },
    };
  }

  _toStrapiItem(item) {
    return { data: this._mapAssociation(item) };
  }

  _extractUserIds(rawMembers) {
    if (!Array.isArray(rawMembers)) return null;

    const ids = rawMembers
      .map((item) => this._toInt(item))
      .filter((id) => id !== null);

    return ids;
  }

  _extractFilters(query = {}) {
    const adminId = this._toInt(query?.['filters[admin][id][$eq]'] || query?.filters?.admin?.id?.$eq);
    const memberId = this._toInt(query?.['filters[members][id][$in]'] || query?.filters?.members?.id?.$in);

    return { adminId, memberId };
  }

  async getAllAssociations(query = {}) {
    const { adminId, memberId } = this._extractFilters(query);

    const where = {};
    const or = [];

    if (adminId) {
      or.push({ adminId });
    }

    if (memberId) {
      or.push({
        members: {
          some: {
            userId: memberId,
          },
        },
      });
    }

    if (or.length) {
      where.OR = or;
    }

    const raw = await prisma.association.findMany({
      where,
      orderBy: { name: 'asc' },
      include: {
        admin: {
          select: {
            id: true,
            username: true,
            email: true,
            role: true,
            blocked: true,
            confirmed: true,
            createdAt: true,
            updatedAt: true,
          },
        },
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                email: true,
                role: true,
                blocked: true,
                confirmed: true,
                createdAt: true,
                updatedAt: true,
              },
            },
          },
        },
      },
    });

    return this._toStrapiCollection(raw);
  }

  async getAssociationById(rawId) {
    const id = this._parseId(rawId);

    const association = await prisma.association.findUnique({
      where: { id },
      include: {
        admin: {
          select: {
            id: true,
            username: true,
            email: true,
            role: true,
            blocked: true,
            confirmed: true,
            createdAt: true,
            updatedAt: true,
          },
        },
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                email: true,
                role: true,
                blocked: true,
                confirmed: true,
                createdAt: true,
                updatedAt: true,
              },
            },
          },
        },
      },
    });

    if (!association) {
      throw new NotFoundError('Association non trouvée');
    }

    return this._toStrapiItem(association);
  }

  async createAssociation(body) {
    const payload = this._extractPayload(body);
    const name = String(payload.name || '').trim();

    if (!name) {
      throw new ValidationError('Le nom de l\'association est requis');
    }

    const duplicate = await prisma.association.findFirst({
      where: { name },
    });

    if (duplicate) {
      throw new ConflictError('Une association avec ce nom existe déjà');
    }

    const adminId = this._toInt(payload.adminId ?? payload.admin ?? payload.administrator);
    const memberIds = this._extractUserIds(payload.members);

    const uniqueMemberIds = new Set(memberIds || []);
    if (adminId) uniqueMemberIds.add(adminId);

    const association = await prisma.association.create({
      data: {
        name,
        description: payload.description ? String(payload.description).trim() : null,
        email: payload.email ? String(payload.email).trim() : null,
        phone: payload.phone ? String(payload.phone).trim() : null,
        website: payload.website ? String(payload.website).trim() : null,
        budget: this._toNumber(payload.budget) ?? 0,
        currency: payload.currency ? String(payload.currency).trim() : 'TND',
        verified: this._toBool(payload.verified),
        logoUrl: payload.logoUrl ? String(payload.logoUrl).trim() : null,
        admin: adminId ? { connect: { id: adminId } } : undefined,
        members: uniqueMemberIds.size
          ? {
              create: Array.from(uniqueMemberIds).map((userId) => ({
                user: { connect: { id: userId } },
              })),
            }
          : undefined,
      },
      include: {
        admin: {
          select: {
            id: true,
            username: true,
            email: true,
            role: true,
            blocked: true,
            confirmed: true,
            createdAt: true,
            updatedAt: true,
          },
        },
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                email: true,
                role: true,
                blocked: true,
                confirmed: true,
                createdAt: true,
                updatedAt: true,
              },
            },
          },
        },
      },
    });

    return this._toStrapiItem(association);
  }

  async updateAssociation(rawId, body, userContext = {}) {
    const id = this._parseId(rawId);
    const payload = this._extractPayload(body);

    const existing = await prisma.association.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Association non trouvée');
    }

    // Authorization: Check if user is allowed to update this association
    const { userId, userRole, managerRoles = [] } = userContext;
    const isManager = userRole && managerRoles.includes(userRole);
    
    if (!isManager && userId !== existing.adminId) {
      throw new Error('Vous n\'avez pas les droits pour modifier cette association');
    }

    const nextName = payload.name !== undefined ? String(payload.name).trim() : existing.name;
    if (nextName && nextName !== existing.name) {
      const duplicate = await prisma.association.findFirst({ where: { name: nextName } });
      if (duplicate) {
        throw new ConflictError('Une association avec ce nom existe déjà');
      }
    }

    const adminIdValue = payload.adminId ?? payload.admin ?? payload.administrator;
    const adminId = adminIdValue !== undefined ? this._toInt(adminIdValue) : undefined;

    const memberIds = payload.members !== undefined ? this._extractUserIds(payload.members) : undefined;

    const data = {
      name: payload.name !== undefined ? nextName : undefined,
      description: payload.description !== undefined ? String(payload.description).trim() : undefined,
      email: payload.email !== undefined ? (payload.email ? String(payload.email).trim() : null) : undefined,
      phone: payload.phone !== undefined ? (payload.phone ? String(payload.phone).trim() : null) : undefined,
      website: payload.website !== undefined ? (payload.website ? String(payload.website).trim() : null) : undefined,
      budget: payload.budget !== undefined ? (this._toNumber(payload.budget) ?? 0) : undefined,
      currency: payload.currency !== undefined ? String(payload.currency).trim() : undefined,
      verified: payload.verified !== undefined ? this._toBool(payload.verified) : undefined,
      logoUrl: payload.logoUrl !== undefined ? (payload.logoUrl ? String(payload.logoUrl).trim() : null) : undefined,
      admin: adminIdValue !== undefined
        ? (adminId ? { connect: { id: adminId } } : { disconnect: true })
        : undefined,
    };

    await prisma.$transaction(async (tx) => {
      await tx.association.update({
        where: { id },
        data,
      });

      if (memberIds !== undefined) {
        await tx.associationMember.deleteMany({ where: { associationId: id } });

        const finalMemberIds = new Set(memberIds);
        if (adminId) finalMemberIds.add(adminId);

        if (finalMemberIds.size) {
          await tx.associationMember.createMany({
            data: Array.from(finalMemberIds).map((userId) => ({
              associationId: id,
              userId,
            })),
            skipDuplicates: true,
          });
        }
      }
    });

    return this.getAssociationById(id);
  }

  async deleteAssociation(rawId) {
    const id = this._parseId(rawId);

    const association = await prisma.association.findUnique({ where: { id } });
    if (!association) {
      throw new NotFoundError('Association non trouvée');
    }

    await prisma.association.delete({ where: { id } });
    return { data: { id, deleted: true } };
  }
}

module.exports = new AssociationsService();
