const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'sunspace-secret-jwt-2024';
const JWT_EXPIRY = process.env.JWT_EXPIRY || '7d';

/**
 * Générer un JWT pour un utilisateur
 * @param {Object} user - Données utilisateur
 * @returns {string} Token JWT
 */
const generateToken = (user) => {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      username: user.username,
      role: user.role,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRY }
  );
};

/**
 * Vérifier et décoder un JWT
 * @param {string} token - Token JWT
 * @returns {Object|null} Données du token ou null si invalide
 */
const verifyToken = (token) => {
  try {
    // Enlever le préfixe "Bearer " si présent
    const cleanToken = token.startsWith('Bearer ') ? token.slice(7) : token;
    return jwt.verify(cleanToken, JWT_SECRET);
  } catch (error) {
    console.error('JWT Verification Error:', error.message);
    return null;
  }
};

/**
 * Extraire le token des headers
 * @param {Object} headers - Headers HTTP
 * @returns {string|null} Token ou null
 */
const extractTokenFromHeaders = (headers) => {
  const authHeader = headers.authorization || headers.Authorization;
  if (!authHeader) return null;

  if (authHeader.startsWith('Bearer ')) {
    return authHeader.slice(7);
  }

  return authHeader;
};

module.exports = {
  generateToken,
  verifyToken,
  extractTokenFromHeaders,
};
