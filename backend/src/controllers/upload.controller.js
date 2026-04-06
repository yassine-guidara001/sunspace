const uploadService = require('../services/upload.service');

class UploadController {
  async upload(req, res, next) {
    try {
      const files = req.files || (req.file ? [req.file] : []);
      const saved = await uploadService.saveFiles(files);
      return res.status(200).json(saved);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UploadController();
