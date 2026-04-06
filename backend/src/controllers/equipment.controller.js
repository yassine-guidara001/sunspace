const equipmentService = require('../services/equipment.service');

class EquipmentController {
  async getAllEquipments(req, res, next) {
    try {
      const result = await equipmentService.getAllEquipments(req.query);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getEquipmentById(req, res, next) {
    try {
      const result = await equipmentService.getEquipmentById(req.params.id);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async createEquipment(req, res, next) {
    try {
      const result = await equipmentService.createEquipment(req.body);
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async updateEquipment(req, res, next) {
    try {
      const result = await equipmentService.updateEquipment(req.params.id, req.body);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async deleteEquipment(req, res, next) {
    try {
      const result = await equipmentService.deleteEquipment(req.params.id);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new EquipmentController();
