const Joi = require('joi');
const { ValidationError } = require('../utils/errors');

/**
 * Middleware de validation
 */
const validate = (schema) => {
  return async (req, res, next) => {
    try {
      const { error, value } = schema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        const details = error.details.map((detail) => ({
          field: detail.path[0],
          message: detail.message,
        }));

        throw new ValidationError('Validation failed', details);
      }

      // Remplacer le body par les données validées
      req.body = value;
      next();
    } catch (err) {
      return res.status(err.statusCode || 400).json({
        statusCode: err.statusCode || 400,
        message: err.message,
        success: false,
        error: {
          message: err.message,
          details: err.details || null,
        },
        timestamp: new Date().toISOString(),
      });
    }
  };
};

module.exports = { validate };
