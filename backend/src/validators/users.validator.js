const Joi = require('joi');
const { ROLES, isSupportedRole } = require('../utils/roles');

const roleSchema = Joi.string()
  .trim()
  .custom((value, helpers) => {
    if (!isSupportedRole(value)) {
      return helpers.error('any.invalid');
    }
    return value;
  }, 'role validation');

/**
 * Schéma de validation pour créer un utilisateur
 */
const createUserSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(255).required().messages({
    'string.empty': 'Username est requis',
    'string.alphanum': 'Username ne peut contenir que des lettres et chiffres',
    'string.min': 'Username doit avoir au moins 3 caractères',
  }),
  email: Joi.string().email().max(255).required().messages({
    'string.empty': 'Email est requis',
    'string.email': 'Email invalide',
  }),
  password: Joi.string().min(6).max(255).optional().messages({
    'string.min': 'Mot de passe doit avoir au moins 6 caractères',
  }),
  role: roleSchema
    .empty('')
    .default(ROLES.ETUDIANT)
    .optional()
    .messages({
      'any.invalid': 'Rôle invalide',
    }),
  confirmed: Joi.boolean().optional().default(true),
  blocked: Joi.boolean().optional().default(false),
}).unknown(false);

/**
 * Schéma de validation pour mettre à jour un utilisateur
 */
const updateUserSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(255).optional(),
  email: Joi.string().email().max(255).optional(),
  password: Joi.string().min(6).max(255).optional(),
  role: roleSchema
    .empty('')
    .optional()
    .messages({
      'any.invalid': 'Rôle invalide',
    }),
  confirmed: Joi.boolean().optional(),
  blocked: Joi.boolean().optional(),
}).unknown(false);

module.exports = {
  createUserSchema,
  updateUserSchema,
};
