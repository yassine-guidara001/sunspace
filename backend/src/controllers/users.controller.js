const usersService = require('../services/users.service');
const { sendSuccess } = require('../utils/response');

/**
 * Controller des utilisateurs
 */
class UsersController {
  /**
   * GET /api/users - Obtenir tous les utilisateurs (Admin uniquement)
   */
  async getAllUsers(req, res, next) {
    try {
      const users = await usersService.getAllUsers();
      return sendSuccess(res, users, 'Utilisateurs récupérés', 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/users/me - Obtenir l'utilisateur actuel
   * Alias pour compatibilité Strapi
   */
  async getCurrentUser(req, res, next) {
    try {
      const user = await usersService.getUserById(req.user.id);
      return sendSuccess(res, { data: user }, 'Profil utilisateur', 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/users/:id - Obtenir un utilisateur
   */
  async getUserById(req, res, next) {
    try {
      const { id } = req.params;
      const user = await usersService.getUserById(parseInt(id));
      return sendSuccess(res, user, 'Utilisateur récupéré', 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/users - Créer un nouvel utilisateur
   */
  async createUser(req, res, next) {
    try {
      const user = await usersService.createUser(req.body);
      return sendSuccess(
        res,
        user,
        'Utilisateur créé avec succès',
        201
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/users/:id - Mettre à jour un utilisateur
   */
  async updateUser(req, res, next) {
    try {
      const { id } = req.params;
      const user = await usersService.updateUser(parseInt(id), req.body);
      return sendSuccess(
        res,
        user,
        'Utilisateur mis à jour avec succès',
        200
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/users/:id - Supprimer un utilisateur
   */
  async deleteUser(req, res, next) {
    try {
      const { id } = req.params;
      const result = await usersService.deleteUser(parseInt(id));
      return sendSuccess(
        res,
        result,
        'Utilisateur supprimé avec succès',
        200
      );
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UsersController();
