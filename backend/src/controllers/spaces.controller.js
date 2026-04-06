const spacesService = require('../services/spaces.service');
const { sendSuccess, sendError } = require('../utils/response');
const { ValidationError } = require('../utils/errors');

/**
 * Contrôleur des espaces
 */
class SpacesController {
  /**
   * GET /api/spaces - Obtenir tous les espaces
   */
  async getAllSpaces(req, res, next) {
    try {
      const spaces = await spacesService.getAllSpaces();
      sendSuccess(res, spaces, 'Espaces récupérés', 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/spaces/:id - Obtenir un espace par ID
   */
  async getSpaceById(req, res, next) {
    try {
      const { id } = req.params;

      if (!id || isNaN(id)) {
        throw new ValidationError('ID espace invalide');
      }

      const space = await spacesService.getSpaceById(parseInt(id, 10));
      sendSuccess(res, space, 'Espace récupéré', 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/spaces - Créer un nouvel espace
   */
  async createSpace(req, res, next) {
    try {
      const space = await spacesService.createSpace(req.body);
      sendSuccess(res, space, 'Espace créé avec succès', 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/spaces/:id - Mettre à jour un espace
   */
  async updateSpace(req, res, next) {
    try {
      const { id } = req.params;

      if (!id || isNaN(id)) {
        throw new ValidationError('ID espace invalide');
      }

      const space = await spacesService.updateSpace(parseInt(id, 10), req.body);
      sendSuccess(res, space, 'Espace mis à jour', 200);
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/spaces/:id - Supprimer un espace
   */
  async deleteSpace(req, res, next) {
    try {
      const { id } = req.params;

      if (!id || isNaN(id)) {
        throw new ValidationError('ID espace invalide');
      }

      const result = await spacesService.deleteSpace(parseInt(id, 10));
      sendSuccess(res, result, 'Espace supprimé', 200);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SpacesController();
