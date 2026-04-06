const { PrismaClient } = require('@prisma/client');
const { NotFoundError, ConflictError, ValidationError } = require('../utils/errors');

const prisma = new PrismaClient();

/**
 * Service des espaces
 */
class SpacesService {
  _hasValue(value) {
    return value !== undefined && value !== null && value !== '';
  }

  _slugify(value) {
    return String(value || '')
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '')
      .slice(0, 90) || 'espace';
  }

  async _buildUniqueSlug(baseName) {
    const baseSlug = this._slugify(baseName);
    let candidate = baseSlug;
    let attempt = 1;

    while (true) {
      const existing = await prisma.space.findUnique({
        where: { slug: candidate },
        select: { id: true },
      });

      if (!existing) {
        return candidate;
      }

      attempt += 1;
      candidate = `${baseSlug}-${attempt}`;
    }
  }

  /**
   * Obtenir tous les espaces
   */
  async getAllSpaces() {
    const spaces = await prisma.space.findMany({
      orderBy: {
        id: 'asc',
      },
      select: {
        id: true,
        slug: true,
        name: true,
        type: true,
        description: true,
        location: true,
        floor: true,
        capacity: true,
        surface: true,
        width: true,
        height: true,
        status: true,
        hourlyRate: true,
        dailyRate: true,
        monthlyRate: true,
        overtimeRate: true,
        currency: true,
        isCoworkingSpace: true,
        allowLimitedReservations: true,
        available24h: true,
        features: true,
        imageUrl: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return spaces;
  }

  /**
   * Obtenir un espace par ID
   */
  async getSpaceById(spaceId) {
    const space = await prisma.space.findUnique({
      where: { id: spaceId },
      select: {
        id: true,
        slug: true,
        name: true,
        type: true,
        description: true,
        location: true,
        floor: true,
        capacity: true,
        surface: true,
        width: true,
        height: true,
        status: true,
        hourlyRate: true,
        dailyRate: true,
        monthlyRate: true,
        overtimeRate: true,
        currency: true,
        isCoworkingSpace: true,
        allowLimitedReservations: true,
        available24h: true,
        features: true,
        imageUrl: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!space) {
      throw new NotFoundError('Espace non trouvé');
    }

    return space;
  }

  /**
   * Créer un nouvel espace
   */
  async createSpace(data) {
    const {
      name,
      type,
      description,
      location,
      floor,
      capacity,
      surface,
      width,
      height,
      status = 'Disponible',
      hourlyRate,
      dailyRate,
      monthlyRate,
      overtimeRate,
      currency = 'TND',
      isCoworkingSpace = false,
      allowLimitedReservations = false,
      available24h = false,
      features,
      imageUrl,
    } = data;

    // Validation
    if (!name || name.trim() === '') {
      throw new ValidationError('Nom de l\'espace requis');
    }

    // Vérifier les doublons
    const existingSpace = await prisma.space.findFirst({
      where: { name: name.trim() },
    });

    if (existingSpace) {
      throw new ConflictError('Un espace avec ce nom existe déjà');
    }

    const slug = await this._buildUniqueSlug(name.trim());

    // Créer l'espace
    const space = await prisma.space.create({
      data: {
        slug,
        name: name.trim(),
        type,
        description,
        location,
        floor,
        capacity: this._hasValue(capacity) ? parseInt(capacity, 10) : null,
        surface: this._hasValue(surface) ? parseFloat(surface) : null,
        width: this._hasValue(width) ? parseFloat(width) : null,
        height: this._hasValue(height) ? parseFloat(height) : null,
        status: status || 'Disponible',
        hourlyRate: this._hasValue(hourlyRate) ? parseFloat(hourlyRate) : null,
        dailyRate: this._hasValue(dailyRate) ? parseFloat(dailyRate) : null,
        monthlyRate: this._hasValue(monthlyRate) ? parseFloat(monthlyRate) : null,
        overtimeRate: this._hasValue(overtimeRate) ? parseFloat(overtimeRate) : null,
        currency: currency || 'TND',
        isCoworkingSpace: Boolean(isCoworkingSpace),
        allowLimitedReservations: Boolean(allowLimitedReservations),
        available24h: Boolean(available24h),
        features,
        imageUrl,
      },
    });

    return space;
  }

  /**
   * Mettre à jour un espace
   */
  async updateSpace(spaceId, data) {
    // Vérifier que l'espace existe
    const existingSpace = await prisma.space.findUnique({
      where: { id: spaceId },
    });

    if (!existingSpace) {
      throw new NotFoundError('Espace non trouvé');
    }

    // Vérifier les doublons si le nom change
    if (data.name && data.name !== existingSpace.name) {
      const duplicate = await prisma.space.findFirst({
        where: { name: data.name.trim() },
      });
      if (duplicate) {
        throw new ConflictError('Un espace avec ce nom existe déjà');
      }
    }

    // Construire les données à mettre à jour
    const updateData = {};
    const allowedFields = [
      'name',
      'type',
      'description',
      'location',
      'floor',
      'capacity',
      'surface',
      'width',
      'height',
      'status',
      'hourlyRate',
      'dailyRate',
      'monthlyRate',
      'overtimeRate',
      'currency',
      'isCoworkingSpace',
      'allowLimitedReservations',
      'available24h',
      'features',
      'imageUrl',
    ];

    allowedFields.forEach((field) => {
      if (data[field] !== undefined) {
        if (['capacity'].includes(field)) {
          updateData[field] = this._hasValue(data[field]) ? parseInt(data[field], 10) : null;
        } else if (['surface', 'width', 'height', 'hourlyRate', 'dailyRate', 'monthlyRate', 'overtimeRate'].includes(field)) {
          updateData[field] = this._hasValue(data[field]) ? parseFloat(data[field]) : null;
        } else if (['isCoworkingSpace', 'allowLimitedReservations', 'available24h'].includes(field)) {
          updateData[field] = Boolean(data[field]);
        } else if (field === 'name' && data[field]) {
          updateData[field] = data[field].trim();
        } else {
          updateData[field] = data[field];
        }
      }
    });

    // Mettre à jour
    const space = await prisma.space.update({
      where: { id: spaceId },
      data: updateData,
    });

    return space;
  }

  /**
   * Supprimer un espace
   */
  async deleteSpace(spaceId) {
    // Vérifier que l'espace existe
    const space = await prisma.space.findUnique({
      where: { id: spaceId },
    });

    if (!space) {
      throw new NotFoundError('Espace non trouvé');
    }

    // Supprimer
    await prisma.space.delete({
      where: { id: spaceId },
    });

    return { success: true, message: 'Espace supprimé avec succès' };
  }
}

module.exports = new SpacesService();
