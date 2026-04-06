const reservationsService = require('../services/reservations.service');

class ReservationsController {
  async getAll(req, res, next) {
    try {
      const result = await reservationsService.getAll(req.query);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async create(req, res, next) {
    try {
      const result = await reservationsService.create(req.body, {
        userId: req.user?.id,
      });
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async update(req, res, next) {
    try {
      const result = await reservationsService.update(req.params.id, req.body);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async remove(req, res, next) {
    try {
      const result = await reservationsService.remove(req.params.id);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReservationsController();
