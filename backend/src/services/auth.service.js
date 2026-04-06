const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');
const {
  ValidationError,
  ConflictError,
  AuthenticationError,
  NotFoundError,
} = require('../utils/errors');
const { generateToken } = require('../utils/jwt');

const prisma = new PrismaClient();

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
        role: 'USER', // Rôle par défaut
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
   * Nettoyer les données utilisateur (enlever le mot de passe)
   */
  _sanitizeUser(user) {
    const { password, ...sanitized } = user;
    return sanitized;
  }
}

module.exports = new AuthService();
