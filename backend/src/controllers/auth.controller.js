const authService = require('../services/auth.service');
const { sendSuccess, sendError } = require('../utils/response');

/**
 * Controller d'authentification
 */
class AuthController {
  /**
   * POST /api/auth/local/register
   * Enregistrer un nouvel utilisateur
   */
  async register(req, res, next) {
    try {
      const { username, email, password } = req.body;

      const result = await authService.register(username, email, password);

      return sendSuccess(
        res,
        result,
        'Inscription réussie',
        201
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/auth/local
   * Authentifier un utilisateur (login)
   * Compatible avec le format Strapi
   */
  async login(req, res, next) {
    try {
      const { identifier, password } = req.body;

      const result = await authService.login(identifier, password);

      return sendSuccess(
        res,
        result,
        'Connexion réussie',
        200
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/auth/me
   * Obtenir l'utilisateur actuel (authentifié)
   */
  async getMe(req, res, next) {
    try {
      const user = await authService.getCurrentUser(req.user.id);

      return sendSuccess(res, { user }, 'Utilisateur actuel', 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/auth/logout
   * Logout (basique, le vrai logout se fait côté client en supprimant le token)
   */
  async logout(req, res, next) {
    try {
      return sendSuccess(
        res,
        null,
        'Déconnexion réussie',
        200
      );
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AuthController();
