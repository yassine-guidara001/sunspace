const trainingSessionsService = require('../services/trainingSessions.service');

class TrainingSessionsController {
  async getAll(req, res, next) {
    try {
      const result = await trainingSessionsService.getSessions(req.query);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getById(req, res, next) {
    try {
      const result = await trainingSessionsService.getSessionById(req.params.id);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async create(req, res, next) {
    try {
      const result = await trainingSessionsService.createSession(req.body, {
        userId: req.user?.id,
      });
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async update(req, res, next) {
    try {
      const result = await trainingSessionsService.updateSession(req.params.id, req.body, {
        userId: req.user?.id,
        userRole: req.user?.role,
      });
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async remove(req, res, next) {
    try {
      const result = await trainingSessionsService.deleteSession(req.params.id);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new TrainingSessionsController();
