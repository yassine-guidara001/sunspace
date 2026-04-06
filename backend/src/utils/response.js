/**
 * Format de réponse standardisé
 */
const formatResponse = (data = null, message = 'Success', statusCode = 200) => {
  return {
    statusCode,
    message,
    success: statusCode >= 200 && statusCode < 300,
    data,
    timestamp: new Date().toISOString(),
  };
};

/**
 * Réponse d'erreur standardisée
 */
const formatError = (error, statusCode = 500) => {
  const message = error.message || error.toString() || 'Internal server error';
  return {
    statusCode,
    message,
    success: false,
    error: {
      message,
      details: error.details || null,
    },
    timestamp: new Date().toISOString(),
  };
};

/**
 * Réponse de succès avec données
 */
const sendSuccess = (res, data, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json(formatResponse(data, message, statusCode));
};

/**
 * Réponse d'erreur
 */
const sendError = (res, error, statusCode = 500) => {
  return res.status(statusCode).json(formatError(error, statusCode));
};

module.exports = {
  formatResponse,
  formatError,
  sendSuccess,
  sendError,
};
