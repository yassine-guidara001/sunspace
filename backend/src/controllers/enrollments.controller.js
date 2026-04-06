const enrollmentsService = require('../services/enrollments.service');

class EnrollmentsController {
  async getAll(req, res, next) {
    try {
      const result = await enrollmentsService.getAll(req.query);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async create(req, res, next) {
    try {
      const result = await enrollmentsService.create(req.body, {
        userId: req.user?.id,
      });
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async delete(req, res, next) {
    try {
      const result = await enrollmentsService.delete(req.params.id);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new EnrollmentsController();
