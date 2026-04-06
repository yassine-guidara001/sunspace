const express = require('express');
const multer = require('multer');
const uploadController = require('../controllers/upload.controller');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/', authMiddleware, upload.array('files'), uploadController.upload);

module.exports = router;
