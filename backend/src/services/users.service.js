const { PrismaClient } = require('@prisma/client');
const bcryptjs = require('bcryptjs');
const { NotFoundError, ConflictError, ValidationError } = require('../utils/errors');
const { ROLES, normalizeRole } = require('../utils/roles');

const prisma = new PrismaClient();

/**
 * Service des utilisateurs
 */
class UsersService {
  /**
   * Obtenir tous les utilisateurs
   */
  async getAllUsers() {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        username: true,
        email: true,
        role: true,
        confirmed: true,
        blocked: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return users;
  }

  /**
   * Obtenir un utilisateur par ID
   */
  async getUserById(userId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        username: true,
        email: true,
        role: true,
        confirmed: true,
        blocked: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      throw new NotFoundError('Utilisateur non trouvé');
    }

    return user;
  }

  /**
   * Créer un nouvel utilisateur
   */
  async createUser(data) {
    let { username, email, password, role = ROLES.ETUDIANT, confirmed = true, blocked = false } = data;

    // Validation
    if (!username || !email) {
      throw new ValidationError('username et email sont requis');
    }

    const normalizedRole = normalizeRole(role);
    role = normalizedRole || ROLES.ETUDIANT;

    // Identifier si omission password et utiliser un mot de passe par défaut
    let finalPassword = password;
    if (!finalPassword || finalPassword.trim() === '') {
      // Générer un mot de passe temporaire
      finalPassword = 'TempPass123@' + Date.now();
    }

    // Vérifier les doublons
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [{ email }, { username }],
      },
    });

    if (existingUser) {
      if (existingUser.email === email) {
        throw new ConflictError('Cet email est déjà utilisé');
      }
      if (existingUser.username === username) {
        throw new ConflictError('Ce username est déjà pris');
      }
    }

    // Hasher le mot de passe
    const hashedPassword = await bcryptjs.hash(finalPassword, 10);

    // Créer l'utilisateur
    const user = await prisma.user.create({
      data: {
        username,
        email,
        password: hashedPassword,
        role,
        confirmed,
        blocked,
      },
    });

    return this._sanitizeUser(user);
  }

  /**
   * Mettre à jour un utilisateur
   */
  async updateUser(userId, data) {
    let { username, email, password, role, confirmed, blocked } = data;

    // Vérifier que l'utilisateur existe
    const existingUser = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!existingUser) {
      throw new NotFoundError('Utilisateur non trouvé');
    }

    // Vérifier les doublons (si email ou username changent)
    if (username && username !== existingUser.username) {
      const duplicate = await prisma.user.findFirst({
        where: { username },
      });
      if (duplicate) {
        throw new ConflictError('Ce username est déjà pris');
      }
    }

    if (email && email !== existingUser.email) {
      const duplicate = await prisma.user.findFirst({
        where: { email },
      });
      if (duplicate) {
        throw new ConflictError('Cet email est déjà utilisé');
      }
    }

    // Valider et nettoyer le rôle si fourni
    if (role) {
      role = normalizeRole(role) || undefined;
    }

    // Construire les données à mettre à jour
    const updateData = {};
    if (username) updateData.username = username;
    if (email) updateData.email = email;
    if (password) updateData.password = await bcryptjs.hash(password, 10);
    if (role) updateData.role = role;
    if (confirmed !== undefined) updateData.confirmed = confirmed;
    if (blocked !== undefined) updateData.blocked = blocked;

    // Mettre à jour
    const user = await prisma.user.update({
      where: { id: userId },
      data: updateData,
    });

    return this._sanitizeUser(user);
  }

  /**
   * Supprimer un utilisateur
   */
  async deleteUser(userId) {
    // Vérifier que l'utilisateur existe
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundError('Utilisateur non trouvé');
    }

    // Supprimer
    await prisma.user.delete({
      where: { id: userId },
    });

    return { success: true, message: 'Utilisateur supprimé avec succès' };
  }

  /**
   * Nettoyer les données utilisateur (enlever le mot de passe)
   */
  _sanitizeUser(user) {
    const { password, ...sanitized } = user;
    return sanitized;
  }
}

module.exports = new UsersService();
