const express = require('express');
const reservationsController = require('../controllers/reservations.controller');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

router.get('/', authMiddleware, reservationsController.getAll);
router.post('/', authMiddleware, reservationsController.create);
router.put('/:id', authMiddleware, reservationsController.update);
router.delete('/:id', authMiddleware, reservationsController.remove);

module.exports = router;
