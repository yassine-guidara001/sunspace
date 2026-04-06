const Joi = require('joi');

/**
 * Schéma de validation pour le login
 */
const loginSchema = Joi.object({
  identifier: Joi.string().min(3).max(255).required().messages({
    'string.empty': 'Email ou username est requis',
    'string.min': 'Email ou username doit avoir au moins 3 caractères',
  }),
  password: Joi.string().min(6).max(255).required().messages({
    'string.empty': 'Mot de passe est requis',
    'string.min': 'Mot de passe doit avoir au moins 6 caractères',
  }),
});

/**
 * Schéma de validation pour l'inscription
 */
const registerSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(255).required().messages({
    'string.empty': 'Username est requis',
    'string.alphanum': 'Username ne peut contenir que des lettres et chiffres',
    'string.min': 'Username doit avoir au moins 3 caractères',
  }),
  email: Joi.string().email().max(255).required().messages({
    'string.empty': 'Email est requis',
    'string.email': 'Email invalide',
  }),
  password: Joi.string().min(6).max(255).required().messages({
    'string.empty': 'Mot de passe est requis',
    'string.min': 'Mot de passe doit avoir au moins 6 caractères',
  }),
  confirmPassword: Joi.string()
    .valid(Joi.ref('password'))
    .required()
    .messages({
      'any.only': 'Les mots de passe ne correspondent pas',
    }),
}).unknown(false);

module.exports = {
  loginSchema,
  registerSchema,
};
