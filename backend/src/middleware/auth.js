const { verifyToken, extractTokenFromHeaders } = require('../utils/jwt');
const { AuthenticationError, AuthorizationError } = require('../utils/errors');
const { sendError } = require('../utils/response');

/**
 * Middleware d'authentification JWT
 */
const authMiddleware = (req, res, next) => {
  try {
    const token = extractTokenFromHeaders(req.headers);

    if (!token) {
      throw new AuthenticationError('Token manquant');
    }

    const decoded = verifyToken(token);
    if (!decoded) {
      throw new AuthenticationError('Token invalide ou expiré');
    }

    req.user = decoded;
    next();
  } catch (error) {
    return sendError(res, error, error.statusCode || 401);
  }
};

/**
 * Middleware de vérification des rôles
 */
const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    try {
      if (!req.user) {
        throw new AuthenticationError('Authentification requise');
      }

      // Normaliser les rôles pour la comparaison (insensible à la casse)
      const userRole = req.user.role || '';
      const normalizedUserRole = userRole.toUpperCase();
      const normalizedAllowedRoles = allowedRoles.map(r => r.toUpperCase());

      if (!normalizedAllowedRoles.includes(normalizedUserRole)) {
        throw new AuthorizationError(
          `Rôle requis: ${allowedRoles.join(' ou ')}`
        );
      }

      next();
    } catch (error) {
      return sendError(res, error, error.statusCode || 403);
    }
  };
};

module.exports = {
  authMiddleware,
  requireRole,
};
