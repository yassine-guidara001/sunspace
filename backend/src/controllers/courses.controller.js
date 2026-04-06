const coursesService = require('../services/courses.service');

class CoursesController {
  async getAllCourses(req, res, next) {
    try {
      const result = await coursesService.getAllCourses(req.query);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getCourseById(req, res, next) {
    try {
      const result = await coursesService.getCourseById(req.params.id);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async createCourse(req, res, next) {
    try {
      const result = await coursesService.createCourse(req.body, {
        userId: req.user?.id,
      });
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async updateCourse(req, res, next) {
    try {
      const result = await coursesService.updateCourse(req.params.id, req.body);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async deleteCourse(req, res, next) {
    try {
      const result = await coursesService.deleteCourse(req.params.id);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CoursesController();
