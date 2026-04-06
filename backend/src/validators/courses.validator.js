const Joi = require('joi');

const COURSE_LEVELS = ['Débutant', 'Intermédiaire', 'Avancé'];
const COURSE_STATUSES = ['Brouillon', 'Publié'];

/**
 * Schéma de validation pour créer un cours
 */
const createCourseSchema = Joi.object({
  title: Joi.string().max(255).required().messages({
    'string.empty': 'Titre du cours requis',
    'string.max': 'Titre trop long (max 255 caractères)',
  }),
  description: Joi.string().allow('', null).optional(),
  level: Joi.string().valid(...COURSE_LEVELS).optional().default('Débutant').messages({
    'any.only': 'Niveau invalide',
  }),
  price: Joi.number().min(0).optional().default(0).messages({
    'number.base': 'Prix invalide',
    'number.min': 'Le prix doit être supérieur ou égal à 0',
  }),
  status: Joi.string().valid(...COURSE_STATUSES).optional().default('Brouillon').messages({
    'any.only': 'Statut invalide',
  }),
}).unknown(false);

/**
 * Schéma de validation pour mettre à jour un cours
 */
const updateCourseSchema = Joi.object({
  title: Joi.string().max(255).optional().messages({
    'string.max': 'Titre trop long (max 255 caractères)',
  }),
  description: Joi.string().allow('', null).optional(),
  level: Joi.string().valid(...COURSE_LEVELS).optional().messages({
    'any.only': 'Niveau invalide',
  }),
  price: Joi.number().min(0).optional().messages({
    'number.base': 'Prix invalide',
    'number.min': 'Le prix doit être supérieur ou égal à 0',
  }),
  status: Joi.string().valid(...COURSE_STATUSES).optional().messages({
    'any.only': 'Statut invalide',
  }),
}).unknown(false);

module.exports = {
  COURSE_LEVELS,
  COURSE_STATUSES,
  createCourseSchema,
  updateCourseSchema,
};
