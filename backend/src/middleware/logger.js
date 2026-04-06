/**
 * Middleware de logging
 */
const requestLogger = (req, res, next) => {
  const start = Date.now();

  // Intercepter la réponse
  const originalJson = res.json;
  res.json = function (data) {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} - Status: ${res.statusCode} - ${duration}ms`);
    return originalJson.call(this, data);
  };

  next();
};

module.exports = {
  requestLogger,
};
