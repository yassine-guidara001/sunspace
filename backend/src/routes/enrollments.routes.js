const express = require('express');
const enrollmentsController = require('../controllers/enrollments.controller');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

router.get('/', authMiddleware, enrollmentsController.getAll);
router.post('/', authMiddleware, enrollmentsController.create);
router.delete('/:id', authMiddleware, enrollmentsController.delete);

module.exports = router;
