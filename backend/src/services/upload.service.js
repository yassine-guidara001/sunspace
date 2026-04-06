const fs = require('fs');
const path = require('path');

class UploadService {
  constructor() {
    this.uploadDir = path.join(__dirname, '..', '..', 'uploads');
    this.publicBasePath = '/uploads';
    this._sequence = 0;
    this._ensureUploadDir();
  }

  _ensureUploadDir() {
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  _sanitizeFileName(name) {
    return String(name || 'file')
      .trim()
      .replace(/[^a-zA-Z0-9._-]/g, '_');
  }

  _buildPublicUrl(fileName) {
    return `${this.publicBasePath}/${encodeURIComponent(fileName)}`;
  }

  _generateSafeId() {
    this._sequence = (this._sequence + 1) % 1000000;
    const timePart = Date.now() % 2147483647;
    const randomPart = Math.floor(Math.random() * 1000000);
    const candidate = (timePart + randomPart + this._sequence) % 2147483647;
    return candidate > 0 ? candidate : 1;
  }

  async saveFiles(files = []) {
    this._ensureUploadDir();

    const normalizedFiles = Array.isArray(files) ? files : [files];
    const saved = [];

    for (const file of normalizedFiles) {
      if (!file) continue;

      const originalName = this._sanitizeFileName(file.originalname || file.filename || 'file');
      const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1e9)}-${originalName}`;
      const targetPath = path.join(this.uploadDir, uniqueName);

      if (file.buffer) {
        fs.writeFileSync(targetPath, file.buffer);
      } else if (file.path) {
        fs.copyFileSync(file.path, targetPath);
      } else {
        throw new Error('Fichier invalide');
      }

      const stats = fs.statSync(targetPath);
      saved.push({
        id: this._generateSafeId(),
        name: originalName,
        url: this._buildPublicUrl(uniqueName),
        size: stats.size,
        mime: file.mimetype || 'application/octet-stream',
        createdAt: new Date().toISOString(),
      });
    }

    return saved;
  }
}

module.exports = new UploadService();
