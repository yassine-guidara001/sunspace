const ROLES = Object.freeze({
  ADMIN: 'Admin',
  ENSEIGNANT: 'Enseignant',
  ETUDIANT: 'Etudiant',
  PROFESSIONNEL: 'Professionnel',
  ASSOCIATION: 'Association',
  GESTIONNAIRE_ESPACE: "Gestionnaire d'espace",
});

const SUPPORTED_ROLES = Object.freeze(Object.values(ROLES));

const MANAGER_ROLES = Object.freeze([
  ROLES.ADMIN,
  ROLES.ENSEIGNANT,
  ROLES.PROFESSIONNEL,
  ROLES.ASSOCIATION,
  ROLES.GESTIONNAIRE_ESPACE,
]);

const ROLE_FILTERS = Object.freeze({
  ETUDIANTS: Object.freeze([
    ROLES.ETUDIANT,
    'STUDENT',
    'Student',
    'Authenticated',
    'USER',
  ]),
  ENSEIGNANTS: Object.freeze([
    ROLES.ENSEIGNANT,
    'TEACHER',
    'Teacher',
    'TEACHERDIRECTOR',
    'Formateur',
  ]),
});

const normalizeRoleToken = (value) => String(value)
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '')
  .replace(/[\s'_-]+/g, '')
  .toUpperCase();

const ROLE_ALIASES = new Map([
  ['ADMIN', ROLES.ADMIN],
  ['SUPERADMIN', ROLES.ADMIN],

  ['ENSEIGNANT', ROLES.ENSEIGNANT],
  ['TEACHER', ROLES.ENSEIGNANT],
  ['TEACHERDIRECTOR', ROLES.ENSEIGNANT],

  ['ETUDIANT', ROLES.ETUDIANT],
  ['STUDENT', ROLES.ETUDIANT],
  ['USER', ROLES.ETUDIANT],
  ['AUTHENTICATED', ROLES.ETUDIANT],
  ['PUBLIC', ROLES.ETUDIANT],

  ['PROFESSIONNEL', ROLES.PROFESSIONNEL],
  ['TECHNICIAN', ROLES.PROFESSIONNEL],

  ['ASSOCIATION', ROLES.ASSOCIATION],

  ['GESTIONNAIREDESPACE', ROLES.GESTIONNAIRE_ESPACE],
  ['SPACEMANAGER', ROLES.GESTIONNAIRE_ESPACE],
]);

const normalizeRole = (role) => {
  if (role === undefined || role === null) return null;
  const trimmed = String(role).trim();
  if (!trimmed) return null;

  const normalizedToken = normalizeRoleToken(trimmed);
  return ROLE_ALIASES.get(normalizedToken) || null;
};

const isSupportedRole = (role) => Boolean(normalizeRole(role));

const normalizeAllowedRoles = (roles = []) => {
  const normalized = roles
    .map((role) => normalizeRole(role))
    .filter(Boolean);
  return Array.from(new Set(normalized));
};

const hasAnyRole = (userRole, allowedRoles = []) => {
  const normalizedUserRole = normalizeRole(userRole);
  if (!normalizedUserRole) return false;
  return normalizeAllowedRoles(allowedRoles).includes(normalizedUserRole);
};

module.exports = {
  ROLES,
  SUPPORTED_ROLES,
  MANAGER_ROLES,
  ROLE_FILTERS,
  normalizeRole,
  isSupportedRole,
  normalizeAllowedRoles,
  hasAnyRole,
};
