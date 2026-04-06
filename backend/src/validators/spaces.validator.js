const Joi = require('joi');

/**
 * Schéma de validation pour créer un espace
 */
const createSpaceSchema = Joi.object({
  name: Joi.string().max(255).required().messages({
    'string.empty': 'Nom de l\'espace requis',
    'string.max': 'Nom trop long (max 255 caractères)',
  }),
  type: Joi.string().max(100).optional(),
  description: Joi.string().allow('', null).optional(),
  location: Joi.string().max(255).optional(),
  floor: Joi.string().max(50).optional(),
  capacity: Joi.number().integer().min(1).optional(),
  surface: Joi.number().min(0).allow(null).optional(),
  width: Joi.number().min(0).allow(null).optional(),
  height: Joi.number().min(0).allow(null).optional(),
  status: Joi.string().max(50).optional().default('Disponible'),
  
  // Tarification
  hourlyRate: Joi.number().min(0).allow(null).optional(),
  dailyRate: Joi.number().min(0).allow(null).optional(),
  monthlyRate: Joi.number().min(0).allow(null).optional(),
  overtimeRate: Joi.number().min(0).allow(null).optional(),
  currency: Joi.string().max(10).optional().default('TND'),
  
  // Caractéristiques
  isCoworkingSpace: Joi.boolean().optional().default(false),
  allowLimitedReservations: Joi.boolean().optional().default(false),
  available24h: Joi.boolean().optional().default(false),
  features: Joi.string().allow('', null).optional(),
  imageUrl: Joi.string().max(500).allow('', null).optional(),
}).unknown(false);

/**
 * Schéma de validation pour mettre à jour un espace
 */
const updateSpaceSchema = Joi.object({
  name: Joi.string().max(255).optional(),
  type: Joi.string().max(100).optional(),
  description: Joi.string().allow('', null).optional(),
  location: Joi.string().max(255).optional(),
  floor: Joi.string().max(50).optional(),
  capacity: Joi.number().integer().min(1).optional(),
  surface: Joi.number().min(0).allow(null).optional(),
  width: Joi.number().min(0).allow(null).optional(),
  height: Joi.number().min(0).allow(null).optional(),
  status: Joi.string().max(50).optional(),
  
  // Tarification
  hourlyRate: Joi.number().min(0).allow(null).optional(),
  dailyRate: Joi.number().min(0).allow(null).optional(),
  monthlyRate: Joi.number().min(0).allow(null).optional(),
  overtimeRate: Joi.number().min(0).allow(null).optional(),
  currency: Joi.string().max(10).optional(),
  
  // Caractéristiques
  isCoworkingSpace: Joi.boolean().optional(),
  allowLimitedReservations: Joi.boolean().optional(),
  available24h: Joi.boolean().optional(),
  features: Joi.string().allow('', null).optional(),
  imageUrl: Joi.string().max(500).allow('', null).optional(),
}).unknown(false);

module.exports = {
  createSpaceSchema,
  updateSpaceSchema,
};
