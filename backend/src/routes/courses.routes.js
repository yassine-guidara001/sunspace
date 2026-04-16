const express = require('express');
const coursesController = require('../controllers/courses.controller');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { createCourseSchema, updateCourseSchema } = require('../validators/courses.validator');
const { MANAGER_ROLES } = require('../utils/roles');

const router = express.Router();

const managerRoles = MANAGER_ROLES;

// GET /api/courses
router.get('/', authMiddleware, coursesController.getAllCourses);

// GET /api/courses/:id
router.get('/:id', authMiddleware, coursesController.getCourseById);

// POST /api/courses
router.post(
  '/',
  authMiddleware,
  requireRole(...managerRoles),
  validate(createCourseSchema),
  coursesController.createCourse
);

// PUT /api/courses/:id
router.put(
  '/:id',
  authMiddleware,
  requireRole(...managerRoles),
  validate(updateCourseSchema),
  coursesController.updateCourse
);

// DELETE /api/courses/:id
router.delete(
  '/:id',
  authMiddleware,
  requireRole(...managerRoles),
  coursesController.deleteCourse
);

module.exports = router;
