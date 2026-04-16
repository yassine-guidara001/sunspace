const { verifyToken, extractTokenFromHeaders } = require('../utils/jwt');
const { AuthenticationError, AuthorizationError } = require('../utils/errors');
const { sendError } = require('../utils/response');
const { hasAnyRole, normalizeAllowedRoles } = require('../utils/roles');

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

      const userRole = req.user.role;
      const normalizedAllowedRoles = normalizeAllowedRoles(allowedRoles);

      if (!hasAnyRole(userRole, normalizedAllowedRoles)) {
        throw new AuthorizationError(
          `Rôle requis: ${normalizedAllowedRoles.join(' ou ')}`
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
