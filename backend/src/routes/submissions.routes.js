const express = require('express');
const submissionsController = require('../controllers/submissions.controller');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

router.get('/', authMiddleware, submissionsController.getAll);
router.post('/', authMiddleware, submissionsController.create);

module.exports = router;
