const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { PrismaClient } = require('@prisma/client');
const {
  ValidationError,
  ConflictError,
  AuthenticationError,
  NotFoundError,
} = require('../utils/errors');
const { generateToken } = require('../utils/jwt');
const { ROLES } = require('../utils/roles');

const prisma = new PrismaClient();
const mailService = require('./mail.service');

/**
 * Service d'authentification
 */
class AuthService {
  /**
   * Enregistrer un nouvel utilisateur
   */
  async register(username, email, password) {
    // Vérifier si l'utilisateur existe déjà
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
    const hashedPassword = await bcrypt.hash(password, 10);

    // Créer l'utilisateur
    const user = await prisma.user.create({
      data: {
        username,
        email,
        password: hashedPassword,
        role: ROLES.ETUDIANT,
        confirmed: true, // À adapter selon votre logique d'email
        blocked: false,
      },
    });

    // Générer un token
    const token = generateToken(user);

    return {
      user: this._sanitizeUser(user),
      token,
      jwt: token, // Compatibilité Strapi
    };
  }

  /**
   * Authentifier un utilisateur (login)
   */
  async login(identifier, password) {
    // identifier peut être un email ou un username
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { username: identifier },
        ],
      },
    });

    if (!user) {
      throw new AuthenticationError(
        'Email/username ou mot de passe incorrect'
      );
    }

    if (user.blocked) {
      throw new AuthenticationError('Compte bloqué');
    }

    // Comparer les mots de passe
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new AuthenticationError(
        'Email/username ou mot de passe incorrect'
      );
    }

    // Générer un token
    const token = generateToken(user);

    return {
      user: this._sanitizeUser(user),
      token,
      jwt: token, // Compatibilité Strapi
    };
  }

  /**
   * Obtenir un utilisateur par ID
   */
  async getUserById(userId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundError('Utilisateur non trouvé');
    }

    return this._sanitizeUser(user);
  }

  /**
   * Obtenir l'utilisateur actuel (authentifié)
   */
  async getCurrentUser(userId) {
    return this.getUserById(userId);
  }

  /**
   * Changer le mot de passe d'un utilisateur
   */
  async changePassword(userId, currentPassword, newPassword) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundError('Utilisateur non trouvé');
    }

    const isCurrentValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentValid) {
      throw new AuthenticationError('Mot de passe actuel incorrect');
    }

    const sameAsCurrent = await bcrypt.compare(newPassword, user.password);
    if (sameAsCurrent) {
      throw new ValidationError(
        'Le nouveau mot de passe doit être différent de l\'ancien'
      );
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
    });
  }

  async forgotPassword(email, frontendOrigin = null) {
    const normalizedEmail = String(email || '').trim().toLowerCase();
    const user = await prisma.user.findFirst({
      where: { email: normalizedEmail },
    });

    if (!user) {
      return { delivered: false };
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetPasswordTokenHash = crypto
      .createHash('sha256')
      .update(resetToken)
      .digest('hex');
    const resetPasswordExpiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        resetPasswordTokenHash,
        resetPasswordExpiresAt,
      },
    });

    const mailResult = await mailService.sendPasswordResetEmail({
      email: user.email,
      username: user.username,
      resetToken,
      expiresAt: resetPasswordExpiresAt,
      frontendOrigin,
    });

    return {
      delivered: mailResult.delivered,
      resetUrl: mailResult.resetUrl,
      expiresAt: resetPasswordExpiresAt,
    };
  }

  async resetPassword(token, newPassword) {
    const normalizedToken = String(token || '').trim();
    const tokenHash = crypto
      .createHash('sha256')
      .update(normalizedToken)
      .digest('hex');

    const user = await prisma.user.findFirst({
      where: {
        resetPasswordTokenHash: tokenHash,
        resetPasswordExpiresAt: {
          gt: new Date(),
        },
      },
    });

    if (!user) {
      throw new ValidationError('Token de réinitialisation invalide ou expiré');
    }

    const sameAsCurrent = await bcrypt.compare(newPassword, user.password);
    if (sameAsCurrent) {
      throw new ValidationError(
        'Le nouveau mot de passe doit être différent de l\'ancien'
      );
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        resetPasswordTokenHash: null,
        resetPasswordExpiresAt: null,
      },
    });

    return true;
  }

  /**
   * Nettoyer les données utilisateur (enlever le mot de passe)
   */
  _sanitizeUser(user) {
    const { password, ...sanitized } = user;
    return sanitized;
  }
}

module.exports = new AuthService();
