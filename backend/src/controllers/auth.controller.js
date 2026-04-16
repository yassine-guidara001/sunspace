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

  /**
   * POST /api/auth/change-password
   * Changer le mot de passe de l'utilisateur authentifié
   */
  async changePassword(req, res, next) {
    try {
      const { currentPassword, newPassword } = req.body;

      await authService.changePassword(
        req.user.id,
        currentPassword,
        newPassword
      );

      return sendSuccess(
        res,
        null,
        'Mot de passe mis à jour avec succès',
        200
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/auth/forgot-password
   * Générer un token de réinitialisation et envoyer l'email
   */
  async forgotPassword(req, res, next) {
    try {
      const { email } = req.body;
      const result = await authService.forgotPassword(email, req.headers.origin);

      const payload = {
        message:
          'Si un compte existe avec cet email, un lien de réinitialisation a été envoyé.',
      };

      if (process.env.NODE_ENV !== 'production') {
        payload.delivery = result.delivered ? 'sent' : 'simulated';
      }

      if (process.env.NODE_ENV !== 'production' && result.resetUrl) {
        payload.resetUrl = result.resetUrl;
        payload.expiresAt = result.expiresAt;
      }

      return sendSuccess(res, payload, payload.message, 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/auth/reset-password
   * Vérifier le token et changer le mot de passe
   */
  async resetPassword(req, res, next) {
    try {
      const { token, password } = req.body;

      await authService.resetPassword(token, password);

      return sendSuccess(
        res,
        null,
        'Mot de passe réinitialisé avec succès',
        200
      );
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AuthController();
