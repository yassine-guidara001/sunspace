const submissionsService = require('../services/submissions.service');

class SubmissionsController {
  async getAll(req, res, next) {
    try {
      const result = await submissionsService.getAll(req.query);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async create(req, res, next) {
    try {
      const result = await submissionsService.create(req.body, {
        userId: req.user?.id,
      });
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SubmissionsController();
