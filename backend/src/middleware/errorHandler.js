const { formatError } = require('../utils/response');

/**
 * Middleware de gestion des erreurs globales
 */
const errorHandler = (err, req, res, next) => {
  console.error('Error Handler:', {
    message: err.message,
    statusCode: err.statusCode || 500,
    stack: err.stack,
  });

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';

  return res.status(statusCode).json(formatError(
    {
      message,
      details: err.details || null,
    },
    statusCode
  ));
};

module.exports = errorHandler;
