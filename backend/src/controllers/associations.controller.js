const associationsService = require('../services/associations.service');
const { MANAGER_ROLES, ROLES } = require('../utils/roles');

const managerRoles = [...MANAGER_ROLES, ROLES.ASSOCIATION];

class AssociationsController {
  async getAllAssociations(req, res, next) {
    try {
      const result = await associationsService.getAllAssociations(req.query);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getAssociationById(req, res, next) {
    try {
      const result = await associationsService.getAssociationById(req.params.id);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async createAssociation(req, res, next) {
    try {
      const result = await associationsService.createAssociation(req.body);
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async updateAssociation(req, res, next) {
    try {
      // Pass user context to service for authorization check
      const result = await associationsService.updateAssociation(
        req.params.id,
        req.body,
        {
          userId: req.user?.id,
          userRole: req.user?.role,
          managerRoles,
        }
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async deleteAssociation(req, res, next) {
    try {
      const result = await associationsService.deleteAssociation(req.params.id);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AssociationsController();
