const { PrismaClient } = require('@prisma/client');
const {
  ValidationError,
  NotFoundError,
  AuthorizationError,
} = require('../utils/errors');
const { hasAnyRole, ROLES, ROLE_FILTERS } = require('../utils/roles');
const notificationsService = require('./notifications.service');
const reservationsService = require('./reservations.service');
const reservationManager = require('./reservation_manager');

const prisma = new PrismaClient();

const FORUM_ALLOWED_TAGS = new Set([
  'Question de cours',
  'Devoir',
  'Examen',
  'Ressource',
  'Travail de groupe',
  'Problème technique',
  'Autre',
]);

const FORUM_ALLOWED_STATUS = new Set(['OPEN', 'RESOLU', 'EN_ATTENTE']);
const FORUM_ALLOWED_REACTIONS = new Set(['LIKE', 'HELPFUL']);

const ASSISTANT_ROLES = {
  ETUDIANT: 'ETUDIANT',
  ENSEIGNANT: 'ENSEIGNANT',
  PROFESSIONNEL: 'PROFESSIONNEL',
  ADMIN: 'ADMIN',
};

const ASSISTANT_EVENT_TYPES = ['Networking', 'Atelier', 'Conférence', 'Tous'];
const ASSISTANT_FORMATION_DOMAINS = [
  'Tech',
  'Business',
  'Design',
  'Développement personnel',
];

const ASSISTANT_ROLE_SUGGESTIONS = {
  [ASSISTANT_ROLES.ETUDIANT]: [
    'Voir les espaces disponibles aujourd\'hui',
    'Consulter le catalogue de formations',
    'Réserver une salle d\'étude',
    'Donner les devoirs publiés',
    'Donner les cours publiés',
    'Donner les sessions publiées par les enseignants',
    'Donner les sessions de formation en ligne disponibles',
  ],
  [ASSISTANT_ROLES.ENSEIGNANT]: [
    'Quelle est la liste des étudiants inscrits à nos cours ?',
    'Y a-t-il des étudiants qui ont soumis des devoirs ?',
    'Planifier une session de formation',
    'Réserver une salle équipée',
    'Voir les espaces disponibles',
    'Donner les devoirs publiés',
    'Donner les cours publiés',
  ],
  [ASSISTANT_ROLES.PROFESSIONNEL]: [
    'Louer un espace de coworking',
    'Voir les formations',
    'Donner les cours publiés',
    'Donner les sessions de formation en ligne disponibles',
  ],
  [ASSISTANT_ROLES.ADMIN]: [
    'Quelles sont les nouvelles réservations pour aujourd\'hui ?',
    'Donner la liste des réservations en attente',
    'Quelle est la liste des étudiants inscrits à nos cours ?',
    'Y a-t-il des étudiants qui ont soumis des devoirs ?',
    'Voir les espaces disponibles',
    'Consulter les inscriptions',
    'Planifier une session de formation',
  ],
};

const ASSISTANT_GREETING =
  'Bonjour ! Je suis l\'assistant SunSpace. Je suis là pour vous aider avec les espaces, les formations et les événements. Quel est votre profil ?';

class CommunicationService {
  _toInt(value) {
    const parsed = parseInt(String(value), 10);
    if (Number.isNaN(parsed) || parsed <= 0) return null;
    return parsed;
  }

  _extractPayload(body = {}) {
    if (body && typeof body === 'object' && body.data && typeof body.data === 'object') {
      return body.data;
    }
    return body;
  }

  _normalizeAssistantText(value) {
    return String(value || '')
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .trim();
  }

  _extractAssistantSession(payload = {}) {
    const candidate = payload.session;
    if (candidate && typeof candidate === 'object' && !Array.isArray(candidate)) {
      return {
        role: String(candidate.role || '').trim().toUpperCase(),
        awaiting: String(candidate.awaiting || '').trim(),
        reservation: candidate.reservation && typeof candidate.reservation === 'object'
          ? {
              date: String(candidate.reservation.date || '').trim(),
              attendees: this._toInt(candidate.reservation.attendees),
              equipment: Array.isArray(candidate.reservation.equipment)
                ? candidate.reservation.equipment
                    .map((item) => String(item || '').trim())
                    .filter(Boolean)
                    .slice(0, 6)
                : [],
            }
          : {},
        pendingConfirmation:
          candidate.pendingConfirmation && typeof candidate.pendingConfirmation === 'object'
            ? {
                spaceId: this._toInt(candidate.pendingConfirmation.spaceId),
                spaceName: String(candidate.pendingConfirmation.spaceName || '').trim(),
                date: String(candidate.pendingConfirmation.date || '').trim(),
              }
            : null,
        availableSpaces: Array.isArray(candidate.availableSpaces)
          ? candidate.availableSpaces
              .map((item) => ({
                id: this._toInt(item?.id),
                name: String(item?.name || '').trim(),
                date: String(item?.date || '').trim(),
                capacity: this._toInt(item?.capacity),
                slots: Array.isArray(item?.slots)
                  ? item.slots.map((slot) => String(slot || '').trim()).filter(Boolean)
                  : [],
                equipments: Array.isArray(item?.equipments)
                  ? item.equipments.map((equipment) => String(equipment || '').trim()).filter(Boolean)
                  : [],
              }))
              .filter((item) => item.id)
          : [],
        selectedSpace:
          candidate.selectedSpace && typeof candidate.selectedSpace === 'object'
            ? {
                id: this._toInt(candidate.selectedSpace.id),
                name: String(candidate.selectedSpace.name || '').trim(),
                date: String(candidate.selectedSpace.date || '').trim(),
              }
            : null,
      };
    }

    return {
      role: '',
      awaiting: 'role',
      reservation: {},
      pendingConfirmation: null,
      availableSpaces: [],
      selectedSpace: null,
    };
  }

  _assistantResponse(payload = {}) {
    const {
      reply,
      question = '',
      options = [],
      session = {},
      data = null,
    } = payload;

    return {
      data: {
        reply,
        question,
        options,
        session,
        ...(data ? { contextData: data } : {}),
      },
    };
  }

  _detectAssistantRoleFromText(rawText = '') {
    const text = this._normalizeAssistantText(rawText);

    if (!text) return '';
    if (text.includes('etudiant')) return ASSISTANT_ROLES.ETUDIANT;
    if (text.includes('enseignant') || text.includes('formateur')) {
      return ASSISTANT_ROLES.ENSEIGNANT;
    }
    if (
      text.includes('professionnel') ||
      text.includes('entreprise') ||
      text.includes('societe')
    ) {
      return ASSISTANT_ROLES.PROFESSIONNEL;
    }
    if (text.includes('admin') || text.includes('administrateur')) {
      return ASSISTANT_ROLES.ADMIN;
    }

    return '';
  }

  _normalizeAssistantRole(rawRole = '') {
    const value = String(rawRole || '').trim().toUpperCase();
    if (value.includes('ETUD')) return ASSISTANT_ROLES.ETUDIANT;
    if (value.includes('ENSEIGN') || value.includes('FORMATEUR')) {
      return ASSISTANT_ROLES.ENSEIGNANT;
    }
    if (value.includes('PROF')) return ASSISTANT_ROLES.PROFESSIONNEL;
    if (value.includes('ADMIN')) return ASSISTANT_ROLES.ADMIN;
    return '';
  }

  _isAdminRole(role = '') {
    return this._normalizeAssistantText(role).includes('admin');
  }

  _extractAssistantSpaceId(rawText = '') {
    const text = String(rawText || '');

    const explicit = text.match(/(?:espace|space|salle)\s*#?\s*(\d{1,6})/i);
    if (explicit) return this._toInt(explicit[1]);

    const compact = text.match(/(?:espace|space|salle)#?(\d{1,6})/i);
    if (compact) return this._toInt(compact[1]);

    return null;
  }

  _extractAssistantTimes(rawText = '') {
    const text = String(rawText || '').toLowerCase();
    const values = [];

    const hhmmMatches = [...text.matchAll(/\b([01]?\d|2[0-3]):([0-5]\d)\b/g)];
    for (const match of hhmmMatches) {
      values.push({
        hour: parseInt(match[1], 10),
        minute: parseInt(match[2], 10),
      });
    }

    const hourMatches = [...text.matchAll(/\b([01]?\d|2[0-3])\s*h(?:\s*([0-5]?\d))?\b/g)];
    for (const match of hourMatches) {
      values.push({
        hour: parseInt(match[1], 10),
        minute: match[2] ? parseInt(match[2], 10) : 0,
      });
    }

    return values.slice(0, 2);
  }

  _extractAssistantReservationWindow(rawText = '') {
    const dateISO = this._parseAssistantDate(rawText) || this._dateToIso(new Date());
    const times = this._extractAssistantTimes(rawText);
    const now = new Date();

    const buildDate = ({ hour, minute }) => {
      const hh = String(hour).padStart(2, '0');
      const mm = String(minute).padStart(2, '0');
      return new Date(`${dateISO}T${hh}:${mm}:00`);
    };

    let startDate;
    let endDate;

    if (times.length === 0) {
      startDate = new Date(now);
      endDate = new Date(startDate.getTime() + 60 * 60 * 1000);
    } else {
      startDate = buildDate(times[0]);
      if (times.length > 1) {
        endDate = buildDate(times[1]);
      } else {
        endDate = new Date(startDate.getTime() + 60 * 60 * 1000);
      }
    }

    if (endDate <= startDate) {
      endDate = new Date(startDate.getTime() + 60 * 60 * 1000);
    }

    return {
      dateISO,
      startAt: startDate.toISOString(),
      endAt: endDate.toISOString(),
    };
  }

  _extractAssistantReservationsRange(rawText = '') {
    const text = this._normalizeAssistantText(rawText);
    const now = new Date();

    if (text.includes('demain')) {
      const target = new Date(now);
      target.setDate(target.getDate() + 1);
      const start = new Date(target);
      start.setHours(0, 0, 0, 0);
      const end = new Date(target);
      end.setHours(23, 59, 59, 999);
      return { start: start.toISOString(), end: end.toISOString(), label: 'demain' };
    }

    if (text.includes('semaine')) {
      const start = new Date(now);
      const day = start.getDay();
      const diff = day === 0 ? -6 : 1 - day;
      start.setDate(start.getDate() + diff);
      start.setHours(0, 0, 0, 0);

      const end = new Date(start);
      end.setDate(end.getDate() + 6);
      end.setHours(23, 59, 59, 999);
      return { start: start.toISOString(), end: end.toISOString(), label: 'cette semaine' };
    }

    const explicitDate = this._parseAssistantDate(rawText);
    if (explicitDate) {
      const start = new Date(`${explicitDate}T00:00:00`);
      const end = new Date(`${explicitDate}T23:59:59.999`);
      return {
        start: start.toISOString(),
        end: end.toISOString(),
        label: this._formatAssistantDate(explicitDate),
      };
    }

    const today = new Date(now);
    today.setHours(0, 0, 0, 0);
    const todayEnd = new Date(now);
    todayEnd.setHours(23, 59, 59, 999);
    return {
      start: today.toISOString(),
      end: todayEnd.toISOString(),
      label: 'aujourd\'hui',
    };
  }

  _detectAssistantDirectAction(rawText = '') {
    const text = this._normalizeAssistantText(rawText);
    if (!text) return '';

    const wantsCancel = text.includes('annul') || text.includes('cancel');
    const wantsReserve =
      text.includes('reserver') ||
      text.includes('reservation') ||
      text.includes('book') ||
      text.includes('louer');
    const wantsList =
      text.includes('quels') ||
      text.includes('liste') ||
      text.includes('afficher') ||
      text.includes('voir');
    const mentionsReservation = text.includes('reserv');
    const mentionsSpace = text.includes('espace') || text.includes('space') || text.includes('salle');

    if (wantsCancel && mentionsReservation && this._extractAssistantSpaceId(rawText)) {
      return 'cancel';
    }

    if (wantsList && mentionsReservation) {
      return 'list';
    }

    if (wantsReserve && mentionsSpace && this._extractAssistantSpaceId(rawText)) {
      return 'reserve';
    }

    return '';
  }

  _formatReservationTimeRange(startAt, endAt) {
    const start = new Date(startAt);
    const end = new Date(endAt);
    const pad = (value) => String(value).padStart(2, '0');
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      return 'horaire non disponible';
    }
    return `${pad(start.getHours())}h${pad(start.getMinutes())} à ${pad(end.getHours())}h${pad(end.getMinutes())}`;
  }

  async _assistantHandleDirectReservation(rawText = '', context = {}, session = {}) {
    const userId = this._toInt(context.userId);
    const user = await this._resolveUserOrThrow(userId);
    const spaceId = this._extractAssistantSpaceId(rawText);

    if (!spaceId) {
      return this._assistantResponse({
        reply: 'Je peux réserver, mais j\'ai besoin du numéro de l\'espace. Exemple: "réserver espace 3".',
        session,
      });
    }

    const window = this._extractAssistantReservationWindow(rawText);
    const reservation = await reservationManager.reserve_space(user.id, spaceId, window.startAt, {
      endDatetime: window.endAt,
      userName: user.username,
    });

    if (!reservation.ok) {
      if (reservation.code === 'CONFLICT') {
        const conflictRange = this._formatReservationTimeRange(
          reservation.conflict?.startAt,
          reservation.conflict?.endAt
        );
        return this._assistantResponse({
          reply: `❌ Espace ${spaceId} déjà réservé sur ce créneau (${conflictRange}).`,
          session,
        });
      }

      return this._assistantResponse({
        reply: `❌ ${reservation.message || 'Impossible de créer la réservation.'}`,
        session,
      });
    }

    return this._assistantResponse({
      reply:
        `✅ Espace ${spaceId} réservé pour le ${this._formatAssistantDate(window.dateISO)} ` +
        `de ${this._formatReservationTimeRange(reservation.reservation.startAt, reservation.reservation.endAt)}.`,
      session: {
        ...session,
        awaiting: 'intent',
      },
      data: {
        reservation: reservation.reservation,
      },
    });
  }

  async _assistantHandleDirectReservationsList(rawText = '', context = {}, session = {}) {
    const userId = this._toInt(context.userId);
    const user = await this._resolveUserOrThrow(userId);
    const period = this._extractAssistantReservationsRange(rawText);
    const isAdmin = this._isAdminRole(user.role);

    const rows = await reservationManager.get_reservations(period, {
      userId: isAdmin ? null : user.id,
    });

    if (rows.length === 0) {
      return this._assistantResponse({
        reply: isAdmin
          ? `Aucune réservation trouvée pour ${period.label}.`
          : `Vous n\'avez aucune réservation pour ${period.label}.`,
        session,
      });
    }

    const formatted = rows
      .slice(0, 20)
      .map((row) => {
        const start = new Date(row.startAt);
        const dateLabel = Number.isNaN(start.getTime())
          ? period.label
          : this._formatAssistantDate(start.toISOString().slice(0, 10));
        return (
          `📋 Espace ${row.spaceId} réservé par ${row.userName} ` +
          `le ${dateLabel} de ${this._formatReservationTimeRange(row.startAt, row.endAt)}`
        );
      })
      .join('\n');

    return this._assistantResponse({
      reply: formatted,
      session,
      data: {
        reservations: rows,
        period,
      },
    });
  }

  async _assistantHandleDirectCancel(rawText = '', context = {}, session = {}) {
    const userId = this._toInt(context.userId);
    const user = await this._resolveUserOrThrow(userId);
    const spaceId = this._extractAssistantSpaceId(rawText);

    if (!spaceId) {
      return this._assistantResponse({
        reply: 'Je peux annuler, mais j\'ai besoin du numéro de l\'espace. Exemple: "annuler réservation espace 3".',
        session,
      });
    }

    const window = this._extractAssistantReservationWindow(rawText);
    const cancellation = await reservationManager.cancel_reservation(
      user.id,
      spaceId,
      window.startAt,
      {
        isAdmin: this._isAdminRole(user.role),
      }
    );

    if (!cancellation.ok) {
      return this._assistantResponse({
        reply: `❌ ${cancellation.message || 'Annulation impossible.'}`,
        session,
      });
    }

    return this._assistantResponse({
      reply:
        `✅ Réservation de l\'espace ${spaceId} annulée ` +
        `(${this._formatReservationTimeRange(cancellation.reservation.startAt, cancellation.reservation.endAt)}).`,
      session: {
        ...session,
        awaiting: 'intent',
      },
      data: {
        reservation: cancellation.reservation,
      },
    });
  }

  _detectAssistantIntent(rawText = '') {
    const text = this._normalizeAssistantText(rawText);
    const asksAvailability =
      text.includes('disponible') || text.includes('disponibles') || text.includes('libre');
    const asksView =
      text.includes('voir') || text.includes('afficher') || text.includes('montrer') || text.includes('liste');
    const asksBooking =
      text.includes('reserv') || text.includes('reserver') || text.includes('louer');
    const asksPublished =
      text.includes('publie') || text.includes('publier') || text.includes('disponible');
    const asksEnrollments = text.includes('inscrit') || text.includes('inscription');
    const mentionsStudents =
      text.includes('etudiant') || text.includes('student') || text.includes('apprenant');
    const asksSubmissions =
      text.includes('soumis') ||
      text.includes('soumettre') ||
      text.includes('soumission') ||
      text.includes('rendu') ||
      text.includes('submit');
    const asksPending = text.includes('en attente') || text.includes('pending');
    const asksNew =
      text.includes('nouveau') || text.includes('nouvelle') || text.includes('recent');

    if (
      asksEnrollments &&
      mentionsStudents &&
      (text.includes('cours') || text.includes('formation') || text.includes('session'))
    ) {
      return 'teacher_enrollments';
    }

    if (text.includes('devoir') && asksSubmissions) {
      return 'teacher_submissions';
    }

    if (asksPending && (text.includes('reservation') || text.includes('demande'))) {
      return 'admin_pending_reservations';
    }

    if (asksNew && text.includes('reservation')) {
      return 'admin_new_reservations';
    }

    if (
      text.includes('session') &&
      (text.includes('en ligne') || text.includes('ligne') || text.includes('formation'))
    ) {
      return 'online_sessions';
    }

    if (text.includes('session') && asksPublished) {
      return 'published_sessions';
    }

    if (text.includes('cours') && asksPublished) {
      return 'courses_published';
    }

    if (text.includes('devoir') && asksPublished) {
      return 'assignments_published';
    }

    if (
      text.includes('espace') ||
      (text.includes('salle') && (asksAvailability || asksView))
    ) {
      return 'spaces';
    }

    if (asksBooking || (text.includes('salle') && text.includes('reservation')) || text.includes('coworking')) {
      return 'reservation';
    }

    if (text.includes('evenement') || text.includes('atelier') || text.includes('conference')) {
      return 'events';
    }

    if (text.includes('formation') || text.includes('catalogue') || text.includes('cours')) {
      return 'formations';
    }

    if (text.includes('devoir')) {
      return 'assignments';
    }

    return '';
  }

  _parseAssistantDate(rawInput = '') {
    const text = String(rawInput || '').trim();
    if (!text) return null;

    const normalized = this._normalizeAssistantText(text);
    if (normalized.includes('aujourd') || normalized.includes('today')) {
      return this._dateToIso(new Date());
    }
    if (normalized.includes('demain') || normalized.includes('tomorrow')) {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      return this._dateToIso(tomorrow);
    }

    const ymd = text.match(/(\d{4})-(\d{2})-(\d{2})/);
    if (ymd) {
      const iso = `${ymd[1]}-${ymd[2]}-${ymd[3]}`;
      const date = new Date(`${iso}T00:00:00`);
      if (!Number.isNaN(date.getTime())) return iso;
    }

    const dmy = text.match(/(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})/);
    if (dmy) {
      const day = dmy[1].padStart(2, '0');
      const month = dmy[2].padStart(2, '0');
      const iso = `${dmy[3]}-${month}-${day}`;
      const date = new Date(`${iso}T00:00:00`);
      if (!Number.isNaN(date.getTime())) return iso;
    }

    return null;
  }

  _dateToIso(value) {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return null;
    return date.toISOString().slice(0, 10);
  }

  _extractAssistantDateCandidates(rawInput = '') {
    const text = String(rawInput || '');
    const normalized = this._normalizeAssistantText(text);
    const dates = [];

    if (normalized.includes('aujourd')) {
      const todayIso = this._dateToIso(new Date());
      if (todayIso) dates.push(todayIso);
    }

    if (normalized.includes('demain')) {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const tomorrowIso = this._dateToIso(tomorrow);
      if (tomorrowIso) dates.push(tomorrowIso);
    }

    const explicitDate = this._parseAssistantDate(text);
    if (explicitDate) {
      dates.push(explicitDate);
    }

    return [...new Set(dates)];
  }

  _formatAssistantSpacesList(spaces = []) {
    return spaces
      .map(
        (space) =>
          `• ${space.name} | Capacité: ${space.capacity || 'N/A'} | Créneaux: ${space.slots.join(', ')} | Équipements: ${space.equipments.join(', ') || 'Non renseignés'}`
      )
      .join('\n');
  }

  async _buildAssistantAvailabilityAnswer(dates = [], { attendees = null, equipmentNeeds = [] } = {}) {
    const uniqueDates = [...new Set(dates)].slice(0, 2);
    if (uniqueDates.length === 0) {
      return {
        text: '',
        firstSpace: null,
        firstDate: null,
        spacesByDate: [],
      };
    }

    const blocks = [];
    const spacesByDate = [];
    let firstSpace = null;
    let firstDate = null;

    for (const isoDate of uniqueDates) {
      const spaces = await this._findAssistantAvailableSpaces({
        dateISO: isoDate,
        attendees,
        equipmentNeeds,
      });

      spacesByDate.push({
        date: isoDate,
        spaces: spaces.map((space) => ({
          ...space,
          date: isoDate,
        })),
      });

      if (!firstSpace && spaces.length > 0) {
        firstSpace = spaces[0];
        firstDate = isoDate;
      }

      if (spaces.length === 0) {
        blocks.push(
          `Disponibilités pour le ${this._formatAssistantDate(isoDate)}:\nAucun espace disponible selon les créneaux configurés.`
        );
      } else {
        blocks.push(
          `Disponibilités pour le ${this._formatAssistantDate(isoDate)}:\n${this._formatAssistantSpacesList(spaces)}`
        );
      }
    }

    return {
      text: blocks.join('\n\n'),
      firstSpace,
      firstDate,
      spacesByDate,
    };
  }

  _buildAssistantIntentOptions(role = '') {
    const suggestions = this._buildAssistantSuggestionsByRole(role);
    if (suggestions.length > 0) return suggestions;
    return ['Voir les espaces disponibles', 'Consulter les formations', 'Voir les événements'];
  }

  _roleSpaceLabel(role = '') {
    if (role === ASSISTANT_ROLES.ETUDIANT) return 'salles d\'étude';
    if (role === ASSISTANT_ROLES.ENSEIGNANT) return 'salles équipées';
    if (role === ASSISTANT_ROLES.PROFESSIONNEL) return 'espaces de coworking';
    if (role === ASSISTANT_ROLES.ADMIN) return 'espaces';
    return 'espaces';
  }

  _roleSpaceQuestion(role = '') {
    if (role === ASSISTANT_ROLES.ETUDIANT) {
      return 'Voulez-vous voir les salles d\'étude disponibles aujourd\'hui ?';
    }
    if (role === ASSISTANT_ROLES.ENSEIGNANT) {
      return 'Voulez-vous voir les salles équipées disponibles aujourd\'hui ?';
    }
    if (role === ASSISTANT_ROLES.PROFESSIONNEL) {
      return 'Voulez-vous voir les espaces de coworking disponibles aujourd\'hui ?';
    }
    if (role === ASSISTANT_ROLES.ADMIN) {
      return 'Souhaitez-vous voir les nouvelles réservations et les demandes en attente d\'aujourd\'hui ?';
    }
    return 'Voulez-vous voir les espaces disponibles aujourd\'hui ?';
  }

  _roleSelectionQuestion(role = '') {
    if (role === ASSISTANT_ROLES.ETUDIANT) {
      return 'Choisissez une salle d\'étude parmi la liste pour poursuivre la réservation.';
    }
    if (role === ASSISTANT_ROLES.ENSEIGNANT) {
      return 'Choisissez une salle équipée parmi la liste pour poursuivre la réservation.';
    }
    if (role === ASSISTANT_ROLES.PROFESSIONNEL) {
      return 'Choisissez un espace de coworking parmi la liste pour poursuivre la réservation.';
    }
    if (role === ASSISTANT_ROLES.ADMIN) {
      return 'Choisissez un espace parmi la liste pour examiner ou traiter la demande.';
    }
    return 'Choisissez un espace parmi la liste pour poursuivre la réservation.';
  }

  _roleReservationDateQuestion(role = '') {
    return `Pour quelle date souhaitez-vous réserver ${this._roleSpaceLabel(role)} ?`;
  }

  _roleReservationEquipmentQuestion(role = '') {
    return `Quel type d\'équipement souhaitez-vous pour ${this._roleSpaceLabel(role)} ?`;
  }

  _extractAssistantSpaceSelection(rawInput = '', availableSpaces = []) {
    const text = String(rawInput || '').trim();
    if (!text) return null;

    const tokenMatch = text.match(/__SPACE_SELECT__\|(\d+)(?:\|([0-9\-]+))?/i);
    if (tokenMatch) {
      const id = this._toInt(tokenMatch[1]);
      const date = String(tokenMatch[2] || '').trim();
      return (
        availableSpaces.find(
          (space) =>
            space.id === id &&
            (!date || String(space.date || '') === date || !space.date)
        ) || null
      );
    }

    const directId = this._toInt(text);
    if (directId) {
      const byId = availableSpaces.find((space) => space.id === directId);
      if (byId) return byId;
    }

    const normalized = this._normalizeAssistantText(text);
    return (
      availableSpaces.find((space) => {
        const normalizedName = this._normalizeAssistantText(space.name);
        return (
          normalizedName === normalized ||
          normalized.includes(normalizedName) ||
          normalizedName.includes(normalized)
        );
      }) || null
    );
  }

  async _createAssistantReservation(context, selectedSpace, session = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) {
      throw new ValidationError('Utilisateur non authentifié');
    }

    const dateISO = String(selectedSpace.date || session.reservation?.date || '').trim();
    if (!dateISO) {
      throw new ValidationError('Date de réservation manquante');
    }

    const response = await reservationsService.create(
      {
        data: {
          space: selectedSpace.id,
          start_datetime: `${dateISO}T09:00:00`,
          end_datetime: `${dateISO}T18:00:00`,
          is_all_day: true,
          attendees: session.reservation?.attendees || 1,
          mystatus: 'En_attente',
          notes: session.reservation?.equipment?.length
            ? `Équipements demandés: ${session.reservation.equipment.join(', ')}`
            : 'Réservation générée via Assistant SunSpace',
          total_amount: 0,
        },
      },
      { userId }
    );

    return response?.data || null;
  }

  async _listAssistantPublishedAssignments() {
    const now = new Date();

    const rows = await prisma.assignment.findMany({
      where: {
        dueDate: { gte: now },
      },
      include: {
        course: {
          select: {
            id: true,
            title: true,
            status: true,
          },
        },
        instructor: {
          select: {
            username: true,
          },
        },
      },
      orderBy: [{ dueDate: 'asc' }],
      take: 8,
    });

    return rows
      .filter((item) => !item.course || String(item.course.status || '') === 'Publié')
      .map((item) => ({
        title: item.title,
        dueDate: item.dueDate ? this._formatAssistantDate(item.dueDate.toISOString().slice(0, 10)) : '-',
        courseTitle: item.course?.title || 'Cours non renseigné',
        instructor: item.instructor?.username || 'Formateur non renseigné',
      }));
  }

  async _listAssistantPublishedCourses() {
    const rows = await prisma.course.findMany({
      where: {
        status: 'Publié',
      },
      include: {
        instructor: {
          select: {
            username: true,
          },
        },
        sessions: {
          where: {
            startDate: { gte: new Date() },
          },
          orderBy: { startDate: 'asc' },
          take: 1,
          select: {
            startDate: true,
          },
        },
      },
      orderBy: [{ createdAt: 'desc' }],
      take: 8,
    });

    return rows.map((item) => ({
      title: item.title,
      level: item.level || 'Niveau non renseigné',
      instructor: item.instructor?.username || 'Formateur non renseigné',
      nextSession: item.sessions[0]?.startDate
        ? this._formatAssistantDate(item.sessions[0].startDate.toISOString().slice(0, 10))
        : 'Aucune session planifiée',
    }));
  }

  async _listAssistantOnlineSessions() {
    const now = new Date();

    const rows = await prisma.trainingSession.findMany({
      where: {
        mystatus: { in: ['Planifiée', 'En cours'] },
        AND: [
          {
            OR: [
              { type: { contains: 'ligne' } },
              { type: { contains: 'en_ligne' } },
              { meetingUrl: { not: null } },
            ],
          },
          {
            OR: [
              { startDate: null },
              { startDate: { gte: now } },
            ],
          },
        ],
      },
      include: {
        course: {
          select: {
            title: true,
          },
        },
        instructor: {
          select: {
            username: true,
          },
        },
      },
      orderBy: [{ startDate: 'asc' }],
      take: 8,
    });

    return rows.map((item) => ({
      title: item.title,
      courseTitle: item.course?.title || 'Cours non renseigné',
      instructor: item.instructor?.username || 'Formateur non renseigné',
      startDate: item.startDate
        ? this._formatAssistantDate(item.startDate.toISOString().slice(0, 10))
        : 'Date non renseignée',
      status: item.mystatus || 'Planifiée',
    }));
  }

  async _listAssistantPublishedTeacherSessions({ instructorId = null, take = 12 } = {}) {
    const now = new Date();

    const rows = await prisma.trainingSession.findMany({
      where: {
        ...(instructorId ? { instructorId } : {}),
        OR: [{ startDate: null }, { startDate: { gte: now } }],
        course: {
          OR: [
            { status: 'Publié' },
            { status: 'Publie' },
            { status: 'PUBLIE' },
            { status: 'Published' },
            { status: 'published' },
          ],
        },
      },
      include: {
        course: {
          select: {
            title: true,
          },
        },
        instructor: {
          select: {
            username: true,
          },
        },
      },
      orderBy: [{ startDate: 'asc' }, { createdAt: 'desc' }],
      take,
    });

    return rows.map((item) => ({
      title: item.title,
      courseTitle: item.course?.title || 'Cours non renseigné',
      instructor: item.instructor?.username || 'Formateur non renseigné',
      type: item.type || 'Type non renseigné',
      startDate: item.startDate
        ? this._formatAssistantDate(item.startDate.toISOString().slice(0, 10))
        : 'Date non renseignée',
      status: item.mystatus || 'Planifiée',
    }));
  }

  async _listAssistantRecentEnrollments({ instructorId = null, take = 20 } = {}) {
    const rows = await prisma.enrollment.findMany({
      where: {
        ...(instructorId
          ? {
              course: {
                instructorId,
              },
            }
          : {}),
      },
      include: {
        student: {
          select: {
            id: true,
            username: true,
            email: true,
          },
        },
        course: {
          select: {
            id: true,
            title: true,
          },
        },
      },
      orderBy: [{ enrolledAt: 'desc' }],
      take,
    });

    return rows.map((item) => ({
      student: item.student?.username || item.student?.email || `Étudiant #${item.studentId}`,
      course: item.course?.title || `Cours #${item.courseId}`,
      status: item.mystatus || 'Active',
      enrolledAt: item.enrolledAt
        ? this._formatAssistantDate(item.enrolledAt.toISOString().slice(0, 10))
        : '-',
    }));
  }

  async _listAssistantRecentSubmissions({ instructorId = null, take = 20 } = {}) {
    const rows = await prisma.submission.findMany({
      where: {
        ...(instructorId
          ? {
              assignment: {
                instructorId,
              },
            }
          : {}),
      },
      include: {
        student: {
          select: {
            id: true,
            username: true,
            email: true,
          },
        },
        assignment: {
          select: {
            id: true,
            title: true,
            course: {
              select: {
                title: true,
              },
            },
          },
        },
      },
      orderBy: [{ submittedAt: 'desc' }],
      take,
    });

    return rows.map((item) => ({
      student: item.student?.username || item.student?.email || `Étudiant #${item.studentId}`,
      assignment: item.assignment?.title || `Devoir #${item.assignmentId}`,
      course: item.assignment?.course?.title || 'Cours non renseigné',
      submittedAt: item.submittedAt
        ? this._formatAssistantDate(item.submittedAt.toISOString().slice(0, 10))
        : '-',
      status: item.status || 'SUBMITTED',
    }));
  }

  async _listAssistantReservationsSummary({ status = null, createdToday = false, take = 20 } = {}) {
    const now = new Date();
    const dayStart = new Date(now);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(now);
    dayEnd.setHours(23, 59, 59, 999);

    const rows = await prisma.reservation.findMany({
      where: {
        ...(status ? { status } : {}),
        ...(createdToday
          ? {
              createdAt: {
                gte: dayStart,
                lte: dayEnd,
              },
            }
          : {}),
      },
      include: {
        user: {
          select: {
            username: true,
            email: true,
          },
        },
        space: {
          select: {
            name: true,
          },
        },
      },
      orderBy: [{ createdAt: 'desc' }],
      take,
    });

    return rows.map((item) => ({
      id: item.id,
      space: item.space?.name || `Espace #${item.spaceId}`,
      user: item.user?.username || item.user?.email || `Utilisateur #${item.userId}`,
      status: item.status,
      createdAt: this._formatAssistantDate(item.createdAt.toISOString().slice(0, 10)),
      startAt: this._formatAssistantTime(item.startDateTime),
      endAt: this._formatAssistantTime(item.endDateTime),
    }));
  }

  _extractAssistantAttendees(rawInput = '') {
    const text = String(rawInput || '').trim();
    if (!text) return null;

    const direct = this._toInt(text);
    if (direct) return direct;

    const fromSentence = text.match(/\b(\d{1,4})\b/);
    if (!fromSentence) return null;

    return this._toInt(fromSentence[1]);
  }

  _parseAssistantEquipmentList(rawInput = '') {
    const normalized = String(rawInput || '').trim();
    if (!normalized) return [];

    return normalized
      .split(/[,;]|\bet\b/gi)
      .map((part) => String(part || '').trim())
      .filter((part) => part.length > 0)
      .slice(0, 6);
  }

  _isAffirmative(rawInput = '') {
    const text = this._normalizeAssistantText(rawInput);
    return ['oui', 'ok', 'd accord', 'confirmer', 'je confirme'].some((token) =>
      text.includes(token)
    );
  }

  _isNegative(rawInput = '') {
    const text = this._normalizeAssistantText(rawInput);
    return ['non', 'annuler', 'pas maintenant', 'plus tard'].some((token) =>
      text.includes(token)
    );
  }

  _formatAssistantDate(rawIso = '') {
    const date = new Date(`${rawIso}T00:00:00`);
    if (Number.isNaN(date.getTime())) return rawIso;
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    return `${day}/${month}/${year}`;
  }

  _formatAssistantTime(dateValue) {
    const date = new Date(dateValue);
    if (Number.isNaN(date.getTime())) return '--:--';
    const hh = String(date.getHours()).padStart(2, '0');
    const mm = String(date.getMinutes()).padStart(2, '0');
    return `${hh}:${mm}`;
  }

  _buildAssistantSuggestionsByRole(role) {
    return ASSISTANT_ROLE_SUGGESTIONS[role] || [];
  }

  _parseAssistantFeatures(rawFeatures) {
    if (!rawFeatures) return [];
    if (Array.isArray(rawFeatures)) {
      return rawFeatures.map((item) => String(item || '').trim()).filter(Boolean);
    }

    if (typeof rawFeatures === 'string') {
      try {
        const parsed = JSON.parse(rawFeatures);
        if (Array.isArray(parsed)) {
          return parsed.map((item) => String(item || '').trim()).filter(Boolean);
        }
      } catch (_) {
        return rawFeatures
          .split(',')
          .map((item) => String(item || '').trim())
          .filter(Boolean);
      }
    }

    return [];
  }

  _computeFreeSlotsForAssistantDay({ dateISO, openingHour, reservations }) {
    const effectiveOpening =
      !openingHour || openingHour.closed
        ? {
            openTime: '09:00',
            closeTime: '18:00',
            closed: false,
          }
        : openingHour;

    const openAt = new Date(`${dateISO}T${effectiveOpening.openTime}:00`);
    const closeAt = new Date(`${dateISO}T${effectiveOpening.closeTime}:00`);
    if (Number.isNaN(openAt.getTime()) || Number.isNaN(closeAt.getTime()) || openAt >= closeAt) {
      return [];
    }

    const sortedReservations = [...reservations]
      .map((item) => ({
        startDateTime: new Date(item.startDateTime),
        endDateTime: new Date(item.endDateTime),
      }))
      .filter((item) => !Number.isNaN(item.startDateTime.getTime()) && !Number.isNaN(item.endDateTime.getTime()))
      .sort((a, b) => a.startDateTime - b.startDateTime);

    const slots = [];
    let cursor = openAt;

    for (const reservation of sortedReservations) {
      const start = reservation.startDateTime < openAt ? openAt : reservation.startDateTime;
      const end = reservation.endDateTime > closeAt ? closeAt : reservation.endDateTime;

      if (end <= openAt || start >= closeAt) continue;

      if (start > cursor) {
        slots.push(`${this._formatAssistantTime(cursor)} - ${this._formatAssistantTime(start)}`);
      }

      if (end > cursor) {
        cursor = end;
      }
    }

    if (cursor < closeAt) {
      slots.push(`${this._formatAssistantTime(cursor)} - ${this._formatAssistantTime(closeAt)}`);
    }

    return slots.slice(0, 4);
  }

  async _findAssistantAvailableSpaces({ dateISO, attendees, equipmentNeeds = [] }) {
    const dayStart = new Date(`${dateISO}T00:00:00`);
    const dayEnd = new Date(`${dateISO}T23:59:59.999`);
    const weekday = dayStart.getDay();

    const rows = await prisma.space.findMany({
      where: {
        ...(attendees
          ? {
              OR: [{ capacity: null }, { capacity: { gte: attendees } }],
            }
          : {}),
      },
      include: {
        equipment: {
          include: {
            equipment: {
              select: { name: true },
            },
          },
        },
        openingHours: {
          where: { dayOfWeek: weekday },
          take: 1,
        },
        reservations: {
          where: {
            status: { in: ['PENDING', 'CONFIRMED'] },
            startDateTime: { lt: dayEnd },
            endDateTime: { gt: dayStart },
          },
          select: {
            startDateTime: true,
            endDateTime: true,
          },
          orderBy: { startDateTime: 'asc' },
        },
      },
      orderBy: [{ name: 'asc' }],
      take: 25,
    });

    const normalizedNeeds = equipmentNeeds
      .map((item) => this._normalizeAssistantText(item))
      .filter((item) => item.length > 1);

    const filtered = rows
      .map((space) => {
        const equipmentList = space.equipment
          .map((item) => String(item.equipment?.name || '').trim())
          .filter(Boolean);
        const features = this._parseAssistantFeatures(space.features);
        const searchBag = this._normalizeAssistantText(
          `${equipmentList.join(' ')} ${features.join(' ')}`
        );

        const matchesNeeds =
          normalizedNeeds.length === 0 ||
          normalizedNeeds.every((need) => searchBag.includes(need));

        if (!matchesNeeds) return null;

        const openingHour = Array.isArray(space.openingHours) ? space.openingHours[0] : null;
        const slots = this._computeFreeSlotsForAssistantDay({
          dateISO,
          openingHour,
          reservations: space.reservations,
        });

        return {
          id: space.id,
          name: space.name,
          capacity: space.capacity,
          slots,
          equipments: [...new Set([...equipmentList, ...features])].slice(0, 8),
        };
      })
      .filter(Boolean)
      .filter((space) => space.slots.length > 0)
      .slice(0, 5);

    return filtered;
  }

  async _listAssistantFormations(rawDomain = '') {
    const domain = String(rawDomain || '').trim();
    const normalized = this._normalizeAssistantText(domain);
    const keywordByDomain = {
      tech: ['dev', 'code', 'programmation', 'data', 'cloud', 'ia', 'tech'],
      business: ['business', 'marketing', 'vente', 'management', 'finance'],
      design: ['design', 'ux', 'ui', 'graphique', 'creatif'],
      'developpement personnel': ['developpement personnel', 'leadership', 'soft skills'],
    };

    const courses = await prisma.course.findMany({
      where: {
        status: 'Publié',
      },
      include: {
        instructor: {
          select: {
            username: true,
          },
        },
        sessions: {
          where: {
            startDate: { gte: new Date() },
          },
          orderBy: { startDate: 'asc' },
          take: 1,
          select: {
            startDate: true,
            endDate: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 40,
    });

    const domainKey = Object.keys(keywordByDomain).find((key) => normalized.includes(key));
    const keywords = domainKey ? keywordByDomain[domainKey] : [];

    return courses
      .filter((course) => {
        if (keywords.length === 0) return true;
        const searchIn = this._normalizeAssistantText(
          `${course.title || ''} ${course.description || ''}`
        );
        return keywords.some((token) => searchIn.includes(token));
      })
      .slice(0, 6)
      .map((course) => {
        const nextSession = course.sessions[0] || null;
        const title = String(course.title || '').trim() || 'Formation';
        const formateur = course.instructor?.username || 'Non renseigné';

        let duree = 'Non renseignée';
        if (nextSession?.startDate && nextSession?.endDate) {
          const start = new Date(nextSession.startDate);
          const end = new Date(nextSession.endDate);
          const diffMs = end - start;
          if (diffMs > 0) {
            const hours = Math.round(diffMs / (1000 * 60 * 60));
            duree = `${hours}h`;
          }
        }

        return {
          title,
          duration: duree,
          instructor: formateur,
          nextSession: nextSession?.startDate
            ? this._formatAssistantDate(new Date(nextSession.startDate).toISOString().slice(0, 10))
            : 'Aucune session planifiée',
        };
      });
  }

  _isTeacherRole(role = '') {
    return hasAnyRole(role, [ROLES.ENSEIGNANT]);
  }

  _isAdminUserRole(role = '') {
    return hasAnyRole(role, [ROLES.ADMIN]);
  }

  _isStudentRole(role = '') {
    return hasAnyRole(role, [ROLES.ETUDIANT]);
  }

  async _resolveUserOrThrow(userId) {
    const id = this._toInt(userId);
    if (!id) throw new ValidationError('ID utilisateur invalide');

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundError('Utilisateur introuvable');

    return user;
  }

  _mapRecipient(user) {
    return {
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
    };
  }

  async getRecipients(query = {}, context = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const currentUser = await this._resolveUserOrThrow(userId);
    const target = String(query.type || '').toLowerCase();

    const where = { id: { not: userId } };

    if (this._isTeacherRole(currentUser.role)) {
      where.role = { in: ROLE_FILTERS.ETUDIANTS };
    } else if (this._isStudentRole(currentUser.role)) {
      if (target === 'teacher' || target === 'enseignant') {
        where.role = { in: ROLE_FILTERS.ENSEIGNANTS };
      } else {
        where.role = { in: ROLE_FILTERS.ETUDIANTS };
      }
    }

    const recipients = await prisma.user.findMany({
      where,
      orderBy: [{ username: 'asc' }],
      select: {
        id: true,
        username: true,
        email: true,
        role: true,
      },
      take: 100,
    });

    return {
      data: recipients.map((recipient) => this._mapRecipient(recipient)),
    };
  }

  _normalizeTags(rawTags) {
    if (!Array.isArray(rawTags)) return [];

    return rawTags
      .map((tag) => String(tag || '').trim())
      .filter((tag) => tag.length > 0)
      .filter((tag) => FORUM_ALLOWED_TAGS.has(tag))
      .slice(0, 3);
  }

  _normalizeStatus(rawStatus) {
    const status = String(rawStatus || '')
      .trim()
      .toUpperCase()
      .replace('É', 'E');

    if (status === 'RESOLVED' || status === 'RESOLU' || status === 'RÉSOLU') {
      return 'RESOLU';
    }
    if (status === 'PENDING' || status === 'EN_ATTENTE') {
      return 'EN_ATTENTE';
    }
    if (status === 'OPEN') {
      return 'OPEN';
    }
    return null;
  }

  _isPrismaUnknownFieldError(error = null) {
    const text = String(error?.message || error || '').toLowerCase();
    return (
      text.includes('unknown arg') ||
      text.includes('unknown field') ||
      text.includes('does not exist in type') ||
      text.includes('column')
    );
  }

  _withLegacyReplyDefaults(rows = []) {
    return rows.map((thread) => ({
      ...thread,
      replies: Array.isArray(thread.replies)
        ? thread.replies.map((reply) => ({
            likeCount: 0,
            helpfulCount: 0,
            isValidated: false,
            validatedAt: null,
            validatedBy: null,
            ...reply,
          }))
        : [],
    }));
  }

  _tokenizeForumText(value) {
    return String(value || '')
      .toLowerCase()
      .replace(/[^a-z0-9\sàâäéèêëîïôöùûüç]/gi, ' ')
      .split(/\s+/)
      .map((token) => token.trim())
      .filter((token) => token.length >= 3);
  }

  _scoreThreadSimilarity(queryTokens, thread) {
    const threadTokens = new Set([
      ...this._tokenizeForumText(thread.title),
      ...this._tokenizeForumText(thread.body),
      ...((Array.isArray(thread.tags) ? thread.tags : []).flatMap((tag) =>
        this._tokenizeForumText(tag)
      )),
    ]);

    if (queryTokens.length === 0 || threadTokens.size === 0) return 0;

    let overlap = 0;
    for (const token of queryTokens) {
      if (threadTokens.has(token)) overlap += 1;
    }

    return overlap / Math.max(1, queryTokens.length);
  }

  async _notifyForumReply({ thread, replyAuthor, reply }) {
    const notifications = [];

    if (thread.authorId !== replyAuthor.id) {
      notifications.push(
        notificationsService.createNotification({
          userId: thread.authorId,
          type: 'TEACHER_MESSAGE',
          title: this._isTeacherRole(replyAuthor.role)
            ? 'Nouveau commentaire enseignant'
            : 'Nouvelle réponse à votre discussion',
          body: `${replyAuthor.username} a répondu à "${thread.title}".`,
          notificationData: {
            scope: 'forum',
            event: this._isTeacherRole(replyAuthor.role)
              ? 'teacher_reply'
              : 'new_reply',
            threadId: thread.id,
            replyId: reply.id,
          },
        })
      );
    }

    await Promise.allSettled(notifications);
  }

  async sendPrivateMessage(body, context = {}) {
    const payload = this._extractPayload(body);

    const senderId = this._toInt(context.userId);
    const recipientId = this._toInt(payload.recipientId ?? payload.recipient_id);
    const subject = String(payload.subject || '').trim();
    const content = String(payload.body || payload.content || '').trim();

    if (!senderId) {
      throw new ValidationError('Utilisateur non authentifié');
    }

    if (!recipientId) {
      throw new ValidationError('Destinataire requis');
    }

    if (!content) {
      throw new ValidationError('Le message ne peut pas être vide');
    }

    if (senderId === recipientId) {
      throw new ValidationError('Vous ne pouvez pas vous envoyer un message à vous-même');
    }

    const [sender, recipient] = await Promise.all([
      this._resolveUserOrThrow(senderId),
      this._resolveUserOrThrow(recipientId),
    ]);

    const senderIsStudent = this._isStudentRole(sender.role);
    const senderIsTeacher = this._isTeacherRole(sender.role);
    const recipientIsStudent = this._isStudentRole(recipient.role);
    const recipientIsTeacher = this._isTeacherRole(recipient.role);

    if (senderIsStudent && !(recipientIsTeacher || recipientIsStudent)) {
      throw new AuthorizationError(
        'Un étudiant peut communiquer uniquement avec un enseignant ou un autre étudiant'
      );
    }

    if (senderIsTeacher && !recipientIsStudent) {
      throw new AuthorizationError(
        'Un enseignant peut communiquer uniquement avec des apprenants'
      );
    }

    const created = await prisma.privateMessage.create({
      data: {
        senderId,
        recipientId,
        subject: subject || null,
        body: content,
      },
      include: {
        sender: { select: { id: true, username: true, email: true, role: true } },
        recipient: { select: { id: true, username: true, email: true, role: true } },
      },
    });

    return { data: created };
  }

  async getPrivateMessages(query = {}, context = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const box = String(query.box || 'inbox').toLowerCase();
    const skip = this._toInt(query.skip) || 0;
    const take = this._toInt(query.take) || 30;

    const where =
      box === 'sent'
        ? { senderId: userId }
        : box === 'all'
          ? { OR: [{ senderId: userId }, { recipientId: userId }] }
          : { recipientId: userId };

    const [rows, total] = await Promise.all([
      prisma.privateMessage.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          sender: { select: { id: true, username: true, email: true, role: true } },
          recipient: { select: { id: true, username: true, email: true, role: true } },
        },
      }),
      prisma.privateMessage.count({ where }),
    ]);

    return {
      data: rows,
      meta: {
        pagination: {
          total,
          skip,
          take,
        },
      },
    };
  }

  async markPrivateMessageRead(rawMessageId, context = {}) {
    const userId = this._toInt(context.userId);
    const messageId = this._toInt(rawMessageId);

    if (!userId) throw new ValidationError('Utilisateur non authentifié');
    if (!messageId) throw new ValidationError('ID message invalide');

    const existing = await prisma.privateMessage.findUnique({
      where: { id: messageId },
    });

    if (!existing) throw new NotFoundError('Message introuvable');
    if (existing.recipientId !== userId) {
      throw new AuthorizationError('Accès non autorisé à ce message');
    }

    const updated = await prisma.privateMessage.update({
      where: { id: messageId },
      data: { isRead: true, readAt: new Date() },
    });

    return { data: updated };
  }

  async deletePrivateMessages(query = {}, context = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const recipientId = this._toInt(query.recipientId);
    if (recipientId && recipientId === userId) {
      throw new ValidationError('recipientId invalide');
    }

    const where = recipientId
      ? {
          OR: [
            { senderId: userId, recipientId },
            { senderId: recipientId, recipientId: userId },
          ],
        }
      : {
          OR: [{ senderId: userId }, { recipientId: userId }],
        };

    const result = await prisma.privateMessage.deleteMany({ where });

    return {
      data: {
        deleted: result.count,
        recipientId: recipientId || null,
      },
    };
  }

  async deleteOldPrivateMessages(query = {}, context = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const requestedDays = this._toInt(query.days);
    const days = Math.min(Math.max(requestedDays || 30, 7), 3650);
    const recipientId = this._toInt(query.recipientId);

    if (recipientId && recipientId === userId) {
      throw new ValidationError('recipientId invalide');
    }

    const cutoffDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const where = {
      createdAt: { lt: cutoffDate },
      OR: [{ senderId: userId }, { recipientId: userId }],
    };

    if (recipientId) {
      where.AND = [
        {
          OR: [
            { senderId: userId, recipientId },
            { senderId: recipientId, recipientId: userId },
          ],
        },
      ];
    }

    const result = await prisma.privateMessage.deleteMany({ where });

    return {
      data: {
        deleted: result.count,
        days,
        recipientId: recipientId || null,
        cutoff: cutoffDate.toISOString(),
      },
    };
  }

  async createForumThread(body, context = {}) {
    const payload = this._extractPayload(body);

    const authorId = this._toInt(context.userId);
    const title = String(payload.title || '').trim();
    const threadBody = String(payload.body || payload.content || '').trim();
    const tags = this._normalizeTags(payload.tags);

    if (!authorId) throw new ValidationError('Utilisateur non authentifié');
    if (!title) throw new ValidationError('Titre requis');
    if (!threadBody) throw new ValidationError('Contenu requis');

    const created = await prisma.forumThread.create({
      data: {
        authorId,
        title,
        body: threadBody,
        tags,
      },
      include: {
        author: { select: { id: true, username: true, email: true, role: true } },
      },
    });

    return { data: created };
  }

  async getForumThreads(query = {}) {
    const skip = this._toInt(query.skip) || 0;
    const take = this._toInt(query.take) || 30;
    const status = this._normalizeStatus(query.status);

    const where = {};
    if (status && FORUM_ALLOWED_STATUS.has(status)) {
      where.status = status;
    }

    let rows;
    let total;

    try {
      [rows, total] = await Promise.all([
        prisma.forumThread.findMany({
          where,
          skip,
          take,
          orderBy: { createdAt: 'desc' },
          include: {
            author: { select: { id: true, username: true, email: true, role: true } },
            replies: {
              orderBy: { createdAt: 'asc' },
              include: {
                author: { select: { id: true, username: true, email: true, role: true } },
                validatedBy: {
                  select: { id: true, username: true, email: true, role: true },
                },
              },
            },
          },
        }),
        prisma.forumThread.count({ where }),
      ]);
    } catch (error) {
      if (!this._isPrismaUnknownFieldError(error)) throw error;

      [rows, total] = await Promise.all([
        prisma.forumThread.findMany({
          where,
          skip,
          take,
          orderBy: { createdAt: 'desc' },
          include: {
            author: { select: { id: true, username: true, email: true, role: true } },
            replies: {
              orderBy: { createdAt: 'asc' },
              include: {
                author: { select: { id: true, username: true, email: true, role: true } },
              },
            },
          },
        }),
        prisma.forumThread.count({ where }),
      ]);

      rows = this._withLegacyReplyDefaults(rows);
    }

    return {
      data: rows,
      meta: {
        pagination: {
          total,
          skip,
          take,
        },
      },
    };
  }

  async deleteOldForumThreads(query = {}, context = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const user = await this._resolveUserOrThrow(userId);
    const requestedDays = this._toInt(query.days);
    const days = Math.min(Math.max(requestedDays || 30, 7), 3650);
    const cutoffDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const isTeacherOrAdmin =
      this._isTeacherRole(user.role) || this._isAdminUserRole(user.role);

    const where = {
      status: 'RESOLU',
      createdAt: { lt: cutoffDate },
      ...(isTeacherOrAdmin ? {} : { authorId: userId }),
    };

    const result = await prisma.forumThread.deleteMany({ where });

    return {
      data: {
        deleted: result.count,
        days,
        cutoff: cutoffDate.toISOString(),
        scope: isTeacherOrAdmin ? 'all_resolved' : 'own_resolved',
      },
    };
  }

  async deleteForumThreads(query = {}, context = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const user = await this._resolveUserOrThrow(userId);
    const isTeacherOrAdmin =
      this._isTeacherRole(user.role) || this._isAdminUserRole(user.role);

    const where = isTeacherOrAdmin ? {} : { authorId: userId };

    const result = await prisma.forumThread.deleteMany({ where });

    return {
      data: {
        deleted: result.count,
        scope: isTeacherOrAdmin ? 'all_threads' : 'own_threads',
      },
    };
  }

  async addForumReply(rawThreadId, body, context = {}) {
    const payload = this._extractPayload(body);

    const threadId = this._toInt(rawThreadId);
    const authorId = this._toInt(context.userId);
    const replyBody = String(payload.body || payload.content || '').trim();

    if (!threadId) throw new ValidationError('ID discussion invalide');
    if (!authorId) throw new ValidationError('Utilisateur non authentifié');
    if (!replyBody) throw new ValidationError('Réponse vide');

    const [thread, replyAuthor] = await Promise.all([
      prisma.forumThread.findUnique({ where: { id: threadId } }),
      this._resolveUserOrThrow(authorId),
    ]);
    if (!thread) throw new NotFoundError('Discussion introuvable');
    if (thread.status === 'RESOLU') {
      throw new ValidationError('Cette discussion est fermée');
    }

    let created;
    try {
      created = await prisma.forumReply.create({
        data: {
          threadId,
          authorId,
          body: replyBody,
        },
        include: {
          author: { select: { id: true, username: true, email: true, role: true } },
          validatedBy: {
            select: { id: true, username: true, email: true, role: true },
          },
        },
      });
    } catch (error) {
      if (!this._isPrismaUnknownFieldError(error)) throw error;

      created = await prisma.forumReply.create({
        data: {
          threadId,
          authorId,
          body: replyBody,
        },
        include: {
          author: { select: { id: true, username: true, email: true, role: true } },
        },
      });
      created = {
        likeCount: 0,
        helpfulCount: 0,
        isValidated: false,
        validatedAt: null,
        validatedBy: null,
        ...created,
      };
    }

    await this._notifyForumReply({
      thread,
      replyAuthor,
      reply: created,
    });

    return { data: created };
  }

  async addForumReplyFromPayload(body, context = {}) {
    const payload = this._extractPayload(body);
    const threadId = payload.threadId ?? payload.thread_id;
    return this.addForumReply(threadId, payload, context);
  }

  async updateForumThreadStatus(rawThreadId, body, context = {}) {
    const threadId = this._toInt(rawThreadId);
    const userId = this._toInt(context.userId);
    const payload = this._extractPayload(body);
    const status = this._normalizeStatus(payload.status);

    if (!threadId) throw new ValidationError('ID discussion invalide');
    if (!userId) throw new ValidationError('Utilisateur non authentifié');
    if (!status || !FORUM_ALLOWED_STATUS.has(status)) {
      throw new ValidationError('Statut invalide (OPEN, RESOLU, EN_ATTENTE)');
    }

    const [thread, user] = await Promise.all([
      prisma.forumThread.findUnique({ where: { id: threadId } }),
      this._resolveUserOrThrow(userId),
    ]);

    if (!thread) throw new NotFoundError('Discussion introuvable');

    if (!this._isTeacherRole(user.role)) {
      throw new AuthorizationError('Seul un enseignant peut changer le statut');
    }

    const updated = await prisma.forumThread.update({
      where: { id: threadId },
      data: { status },
    });

    return { data: updated };
  }

  async validateForumReply(body, context = {}) {
    const payload = this._extractPayload(body);
    const replyId = this._toInt(payload.replyId ?? payload.reply_id);
    const teacherId = this._toInt(context.userId);

    if (!replyId) throw new ValidationError('Réponse invalide');
    if (!teacherId) throw new ValidationError('Utilisateur non authentifié');

    const teacher = await this._resolveUserOrThrow(teacherId);
    if (!this._isTeacherRole(teacher.role)) {
      throw new AuthorizationError('Seul un enseignant peut valider une réponse');
    }

    const reply = await prisma.forumReply.findUnique({
      where: { id: replyId },
      include: {
        thread: true,
      },
    });

    if (!reply) throw new NotFoundError('Réponse introuvable');

    let updated;
    try {
      await prisma.forumReply.updateMany({
        where: {
          threadId: reply.threadId,
          id: { not: reply.id },
        },
        data: {
          isValidated: false,
          validatedAt: null,
          validatedById: null,
        },
      });

      updated = await prisma.forumReply.update({
        where: { id: reply.id },
        data: {
          isValidated: true,
          validatedAt: new Date(),
          validatedById: teacherId,
        },
        include: {
          author: { select: { id: true, username: true, email: true, role: true } },
          validatedBy: {
            select: { id: true, username: true, email: true, role: true },
          },
        },
      });
    } catch (error) {
      if (this._isPrismaUnknownFieldError(error)) {
        throw new ValidationError(
          'Mise à jour base requise: exécutez "npx prisma db push" puis redémarrez le backend.'
        );
      }
      throw error;
    }

    await prisma.forumThread.update({
      where: { id: reply.threadId },
      data: { status: 'RESOLU' },
    });

    if (reply.authorId !== teacherId) {
      await notificationsService.createNotification({
        userId: reply.authorId,
        type: 'TEACHER_MESSAGE',
        title: 'Réponse validée par l\'enseignant',
        body: `${teacher.username} a validé votre réponse dans "${reply.thread.title}".`,
        notificationData: {
          scope: 'forum',
          event: 'reply_validated',
          threadId: reply.threadId,
          replyId: reply.id,
        },
      });
    }

    return { data: updated };
  }

  async reactToForumReply(body, context = {}) {
    const payload = this._extractPayload(body);
    const replyId = this._toInt(payload.replyId ?? payload.reply_id);
    const reactionType = String(payload.reactionType || payload.type || '')
      .trim()
      .toUpperCase();

    if (!this._toInt(context.userId)) {
      throw new ValidationError('Utilisateur non authentifié');
    }
    if (!replyId) throw new ValidationError('Réponse invalide');
    if (!FORUM_ALLOWED_REACTIONS.has(reactionType)) {
      throw new ValidationError('Réaction invalide (LIKE, HELPFUL)');
    }

    const existing = await prisma.forumReply.findUnique({ where: { id: replyId } });
    if (!existing) throw new NotFoundError('Réponse introuvable');

    let updated;
    try {
      updated = await prisma.forumReply.update({
        where: { id: replyId },
        data:
          reactionType === 'LIKE'
            ? { likeCount: { increment: 1 } }
            : { helpfulCount: { increment: 1 } },
        include: {
          author: { select: { id: true, username: true, email: true, role: true } },
          validatedBy: {
            select: { id: true, username: true, email: true, role: true },
          },
        },
      });
    } catch (error) {
      if (this._isPrismaUnknownFieldError(error)) {
        throw new ValidationError(
          'Mise à jour base requise: exécutez "npx prisma db push" puis redémarrez le backend.'
        );
      }
      throw error;
    }

    return { data: updated };
  }

  async getSimilarForumThreads(query = {}) {
    const text = String(query.q || query.text || '').trim();
    if (!text) {
      return { data: [] };
    }

    const tokens = this._tokenizeForumText(text);
    const candidates = await prisma.forumThread.findMany({
      orderBy: { createdAt: 'desc' },
      take: 80,
      select: {
        id: true,
        title: true,
        body: true,
        status: true,
        tags: true,
        createdAt: true,
      },
    });

    const scored = candidates
      .map((thread) => ({
        ...thread,
        score: this._scoreThreadSimilarity(tokens, thread),
      }))
      .filter((thread) => thread.score >= 0.2)
      .sort((a, b) => b.score - a.score)
      .slice(0, 5);

    return { data: scored };
  }

  async improveForumDraft(body = {}) {
    const payload = this._extractPayload(body);
    const rawTitle = String(payload.title || '').trim();
    const rawContent = String(payload.body || payload.content || '').trim();

    if (!rawTitle && !rawContent) {
      throw new ValidationError('Titre ou contenu requis');
    }

    const normalizedContent = rawContent
      .replace(/\s+/g, ' ')
      .replace(/\s([,.;!?])/g, '$1')
      .trim();

    const suggestedTitle = rawTitle.length > 0
      ? rawTitle[0].toUpperCase() + rawTitle.slice(1)
      : `Question: ${normalizedContent.split(' ').slice(0, 10).join(' ')}`;

    const suggestedTags = this._normalizeTags(payload.tags).length > 0
      ? this._normalizeTags(payload.tags)
      : this._suggestTagsFromText(`${suggestedTitle} ${normalizedContent}`);

    return {
      data: {
        title: suggestedTitle,
        body: normalizedContent,
        tags: suggestedTags,
        note:
          'Assistant local: texte clarifié, titre reformulé et tags suggérés automatiquement.',
      },
    };
  }

  _suggestTagsFromText(text) {
    const value = String(text || '').toLowerCase();
    if (value.includes('devoir') || value.includes('rendu')) {
      return ['Devoir', 'Question de cours'];
    }
    if (value.includes('examen') || value.includes('test')) {
      return ['Examen', 'Question de cours'];
    }
    if (value.includes('erreur') || value.includes('bug') || value.includes('connexion')) {
      return ['Problème technique', 'Autre'];
    }
    if (value.includes('groupe') || value.includes('équipe')) {
      return ['Travail de groupe', 'Ressource'];
    }
    return ['Question de cours', 'Autre'];
  }

  async getForumNotifications(query = {}, context = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const take = this._toInt(query.take) || 20;
    const skip = this._toInt(query.skip) || 0;

    const rows = await prisma.notification.findMany({
      where: {
        userId,
        type: 'TEACHER_MESSAGE',
      },
      orderBy: { createdAt: 'desc' },
      take: take + skip + 40,
    });

    const forumRows = rows.filter((row) => row?.data?.scope === 'forum');
    const paged = forumRows.slice(skip, skip + take);

    return {
      data: paged,
      meta: {
        pagination: {
          total: forumRows.length,
          skip,
          take,
        },
      },
    };
  }

  async closeForumThread(rawThreadId, context = {}) {
    const threadId = this._toInt(rawThreadId);
    const userId = this._toInt(context.userId);

    if (!threadId) throw new ValidationError('ID discussion invalide');
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const [thread, user] = await Promise.all([
      prisma.forumThread.findUnique({ where: { id: threadId } }),
      this._resolveUserOrThrow(userId),
    ]);

    if (!thread) throw new NotFoundError('Discussion introuvable');

    const canClose =
      thread.authorId === userId ||
      this._isTeacherRole(user.role) ||
      String(user.role || '').toLowerCase().includes('admin');

    if (!canClose) {
      throw new AuthorizationError('Vous ne pouvez pas fermer cette discussion');
    }

    const updated = await prisma.forumThread.update({
      where: { id: threadId },
      data: { status: 'EN_ATTENTE' },
    });

    return { data: updated };
  }

  async chatWithSunspaceAssistant(body = {}, context = {}) {
    const payload = this._extractPayload(body);
    const userMessage = String(payload.message || payload.text || '').trim();
    const session = this._extractAssistantSession(payload);
    const explicitRole = this._normalizeAssistantRole(
      payload.profile || payload.activeProfile || ''
    );

    if (explicitRole) {
      session.role = explicitRole;
      if (!session.awaiting || session.awaiting === 'role') {
        session.awaiting = 'intent';
      }
    }

    if (!this._toInt(context.userId)) {
      throw new ValidationError('Utilisateur non authentifié');
    }

    const directAction = this._detectAssistantDirectAction(userMessage);
    if (directAction === 'reserve') {
      return this._assistantHandleDirectReservation(userMessage, context, session);
    }
    if (directAction === 'list') {
      return this._assistantHandleDirectReservationsList(userMessage, context, session);
    }
    if (directAction === 'cancel') {
      return this._assistantHandleDirectCancel(userMessage, context, session);
    }

    if (!userMessage && !session.role) {
      return this._assistantResponse({
        reply: ASSISTANT_GREETING,
        question: 'Quel est votre profil ?',
        options: ['Étudiant', 'Enseignant / Formateur', 'Professionnel', 'Admin'],
        session: {
          ...session,
          awaiting: 'role',
        },
      });
    }

    const detectedRole = this._detectAssistantRoleFromText(userMessage);
    if (detectedRole) {
      const nextSession = {
        ...session,
        role: detectedRole,
        awaiting: 'intent',
      };

      const suggestions = this._buildAssistantSuggestionsByRole(detectedRole);

      return this._assistantResponse({
        reply: 'Profil enregistré. Voici ce que je peux vous proposer :',
        question: 'Souhaitez-vous voir les options maintenant ?',
        options: suggestions,
        session: nextSession,
      });
    }

    if (!session.role) {
      return this._assistantResponse({
        reply: ASSISTANT_GREETING,
        question: 'Quel est votre profil ?',
        options: ['Étudiant', 'Enseignant / Formateur', 'Professionnel', 'Admin'],
        session: {
          ...session,
          awaiting: 'role',
        },
      });
    }

    const interruptionIntent = this._detectAssistantIntent(userMessage);
    const canInterrupt = new Set([
      'spaces',
      'reservation',
      'events',
      'formations',
      'assignments_published',
      'courses_published',
      'published_sessions',
      'online_sessions',
      'teacher_enrollments',
      'teacher_submissions',
      'admin_pending_reservations',
      'admin_new_reservations',
    ]);

    if (
      session.awaiting &&
      session.awaiting !== 'intent' &&
      canInterrupt.has(interruptionIntent)
    ) {
      session.awaiting = 'intent';
    }

    if (session.awaiting === 'reservation_date') {
      if (this._isNegative(userMessage)) {
        return this._assistantResponse({
          reply: 'D\'accord, on arrête cette réservation pour le moment.',
          question: 'Que souhaitez-vous faire maintenant ?',
          options: this._buildAssistantIntentOptions(session.role),
          session: {
            ...session,
            awaiting: 'intent',
            reservation: {},
            pendingConfirmation: null,
            availableSpaces: [],
            selectedSpace: null,
          },
        });
      }

      const dateISO = this._parseAssistantDate(userMessage);
      if (!dateISO) {
        return this._assistantResponse({
          reply: 'Je n\'ai pas compris la date.',
          question: `${this._roleReservationDateQuestion(session.role)} (format JJ/MM/AAAA)`,
          session,
        });
      }

      return this._assistantResponse({
        reply: `Date notée: ${this._formatAssistantDate(dateISO)}.`,
        question: 'Combien de personnes seront présentes ?',
        session: {
          ...session,
          awaiting: 'reservation_attendees',
          reservation: {
            ...session.reservation,
            date: dateISO,
          },
        },
      });
    }

    if (session.awaiting === 'reservation_attendees') {
      const attendees = this._extractAssistantAttendees(userMessage);
      if (!attendees) {
        return this._assistantResponse({
          reply: 'Je n\'ai pas compris le nombre de participants.',
          question: 'Combien de personnes seront présentes ?',
          session,
        });
      }

      return this._assistantResponse({
        reply: `Parfait, ${attendees} participant(s).`,
        question: this._roleReservationEquipmentQuestion(session.role),
        session: {
          ...session,
          awaiting: 'reservation_equipment',
          reservation: {
            ...session.reservation,
            attendees,
          },
        },
      });
    }

    if (session.awaiting === 'reservation_equipment') {
      const equipment = this._parseAssistantEquipmentList(userMessage);
      const reservation = {
        ...session.reservation,
        equipment,
      };

      if (!reservation.date) {
        return this._assistantResponse({
          reply: 'Il manque la date de réservation.',
          question: this._roleReservationDateQuestion(session.role),
          session: {
            ...session,
            awaiting: 'reservation_date',
            reservation,
          },
        });
      }

      const availability = await this._buildAssistantAvailabilityAnswer(
        [reservation.date],
        {
          attendees: reservation.attendees,
          equipmentNeeds: reservation.equipment || [],
        }
      );
      const spaces = availability.spacesByDate[0]?.spaces || [];

      if (spaces.length === 0) {
        if ((reservation.equipment || []).length > 0) {
          const relaxedAvailability = await this._buildAssistantAvailabilityAnswer(
            [reservation.date],
            {
              attendees: reservation.attendees,
              equipmentNeeds: [],
            }
          );
          const relaxedSpaces = relaxedAvailability.spacesByDate[0]?.spaces || [];

          if (relaxedSpaces.length > 0) {
            const availableSpaces = relaxedSpaces.map((space) => ({
              ...space,
              date: reservation.date,
            }));

            return this._assistantResponse({
              reply:
                `Aucun espace ne correspond exactement aux équipements demandés (${reservation.equipment.join(', ')}). ` +
                'Voici les espaces réellement disponibles pour cette date :',
              question: this._roleSelectionQuestion(session.role),
              options: availableSpaces.slice(0, 6).map((space) => space.name),
              session: {
                ...session,
                awaiting: 'space_selection',
                reservation: {
                  ...reservation,
                  equipment: [],
                },
                availableSpaces,
                selectedSpace: null,
                pendingConfirmation: null,
              },
              data: {
                spacesByDate: relaxedAvailability.spacesByDate,
                spaces: availableSpaces,
              },
            });
          }
        }

        return this._assistantResponse({
          reply:
            'Aucun espace ne correspond à vos critères pour cette date avec les créneaux configurés.',
          question: 'Souhaitez-vous changer la date ou les équipements demandés ?',
          options: ['Aujourd\'hui', 'Demain', 'Voir les espaces disponibles'],
          session: {
            ...session,
            awaiting: 'reservation_date',
            reservation: {
              ...reservation,
              equipment: [],
            },
          },
        });
      }

      const availableSpaces = spaces.map((space) => ({
        ...space,
        date: reservation.date,
      }));

      return this._assistantResponse({
        reply: availability.text,
        question: this._roleSelectionQuestion(session.role),
        options: availableSpaces.slice(0, 6).map((space) => space.name),
        session: {
          ...session,
          awaiting: 'space_selection',
          reservation,
          availableSpaces,
          selectedSpace: null,
          pendingConfirmation: null,
        },
        data: {
          spacesByDate: availability.spacesByDate,
          spaces: availableSpaces,
        },
      });
    }

    if (session.awaiting === 'space_selection') {
      const requestedDates = this._extractAssistantDateCandidates(userMessage);
      if (requestedDates.length > 0) {
        const availability = await this._buildAssistantAvailabilityAnswer(requestedDates, {
          attendees: session.reservation?.attendees || null,
          equipmentNeeds: Array.isArray(session.reservation?.equipment)
            ? session.reservation.equipment
            : [],
        });

        if (!availability.firstSpace) {
          return this._assistantResponse({
            reply: availability.text || 'Aucune disponibilité trouvée pour la date demandée.',
            question: 'Souhaitez-vous vérifier une autre date ?',
            options: ['Aujourd\'hui', 'Demain'],
            session: {
              ...session,
              reservation: {
                ...session.reservation,
                date: requestedDates[0],
              },
              availableSpaces: [],
              selectedSpace: null,
              pendingConfirmation: null,
            },
            data: {
              spacesByDate: availability.spacesByDate,
            },
          });
        }

        const availableSpaces = (availability.spacesByDate.flatMap((group) =>
          (group.spaces || []).map((space) => ({
            ...space,
            date: group.date,
          }))
        )).slice(0, 12);

        return this._assistantResponse({
          reply: availability.text,
          question: this._roleSelectionQuestion(session.role),
          options: availableSpaces.slice(0, 6).map((space) => space.name),
          session: {
            ...session,
            reservation: {
              ...session.reservation,
              date: requestedDates[0],
            },
            availableSpaces,
            selectedSpace: null,
            pendingConfirmation: null,
          },
          data: {
            spacesByDate: availability.spacesByDate,
            spaces: availableSpaces,
          },
        });
      }

      const selectedSpace = this._extractAssistantSpaceSelection(
        userMessage,
        session.availableSpaces || []
      );

      if (!selectedSpace) {
        return this._assistantResponse({
          reply: 'Je n\'ai pas reconnu votre choix.',
          question: this._roleSelectionQuestion(session.role),
          options: (session.availableSpaces || []).slice(0, 6).map((space) => space.name),
          session,
          data: {
            spaces: session.availableSpaces || [],
          },
        });
      }

      return this._assistantResponse({
        reply: `Espace choisi: ${selectedSpace.name}.`,
        question: `Souhaitez-vous confirmer la réservation de ${selectedSpace.name} pour le ${this._formatAssistantDate(selectedSpace.date || session.reservation?.date)} de 09:00 à 18:00 ?`,
        options: ['Oui', 'Non'],
        session: {
          ...session,
          awaiting: 'reservation_confirmation',
          selectedSpace: {
            id: selectedSpace.id,
            name: selectedSpace.name,
            date: selectedSpace.date || session.reservation?.date || '',
          },
          pendingConfirmation: {
            spaceId: selectedSpace.id,
            spaceName: selectedSpace.name,
            date: selectedSpace.date || session.reservation?.date || '',
          },
        },
      });
    }

    if (session.awaiting === 'reservation_confirmation' && session.pendingConfirmation) {
      if (this._isAffirmative(userMessage)) {
        let reservation = null;
        try {
          reservation = await this._createAssistantReservation(
            context,
            {
              id: session.pendingConfirmation.spaceId,
              name: session.pendingConfirmation.spaceName,
              date: session.pendingConfirmation.date,
            },
            session
          );
        } catch (error) {
          return this._assistantResponse({
            reply: error.message || 'Impossible de créer la réservation.',
            question: 'Souhaitez-vous choisir un autre espace ?',
            options: this._buildAssistantIntentOptions(session.role),
            session: {
              ...session,
              awaiting: 'intent',
              pendingConfirmation: null,
              selectedSpace: null,
            },
          });
        }

        return this._assistantResponse({
          reply: reservation
            ? `Réservation créée pour ${session.pendingConfirmation.spaceName} le ${this._formatAssistantDate(session.pendingConfirmation.date)}.`
            : 'Votre réservation a été prise en compte.',
          question: 'Puis-je vous aider avec autre chose ?',
          options: this._buildAssistantIntentOptions(session.role),
          session: {
            ...session,
            awaiting: 'intent',
            pendingConfirmation: null,
            selectedSpace: null,
            availableSpaces: [],
            reservation: {},
          },
          data: reservation ? { reservation } : null,
        });
      }

      if (this._isNegative(userMessage)) {
        return this._assistantResponse({
          reply: 'D\'accord, je ne valide pas cette réservation.',
          question: 'Souhaitez-vous changer la date ou vos critères ?',
          session: {
            ...session,
            awaiting: 'reservation_date',
            pendingConfirmation: null,
          },
        });
      }

      return this._assistantResponse({
        reply: 'Je n\'ai pas compris votre réponse.',
        question: `Souhaitez-vous confirmer la réservation de ${session.pendingConfirmation.spaceName} pour le ${this._formatAssistantDate(session.pendingConfirmation.date)} ?`,
        options: ['Oui', 'Non'],
        session,
      });
    }

    if (session.awaiting === 'event_type') {
      const eventType = ASSISTANT_EVENT_TYPES.find((item) =>
        this._normalizeAssistantText(userMessage).includes(this._normalizeAssistantText(item))
      );

      if (!eventType) {
        return this._assistantResponse({
          reply: 'Je n\'ai pas compris le type d\'événement.',
          question: 'Quel type d\'événement vous intéresse ?',
          options: ASSISTANT_EVENT_TYPES,
          session,
        });
      }

      return this._assistantResponse({
        reply:
          'Je ne dispose pas encore du catalogue événements en temps réel dans ce module, donc je ne peux pas afficher une liste fiable.',
        question: 'Souhaitez-vous contacter notre équipe ?',
        options: ['Oui', 'Non'],
        session: {
          ...session,
          awaiting: 'intent',
        },
      });
    }

    if (session.awaiting === 'formation_domain') {
      // Flux simplifié: ne plus proposer le filtrage par domaine.
      session.awaiting = 'intent';
    }

    const intent = this._detectAssistantIntent(userMessage);

    if (session.awaiting === 'intent') {
      if (this._isAffirmative(userMessage)) {
        const suggestions = this._buildAssistantSuggestionsByRole(session.role);
        if (suggestions.length > 0) {
          return this._assistantResponse({
            reply: 'Très bien. Voici les options disponibles :',
            question: 'Que souhaitez-vous faire ?',
            options: suggestions,
            session,
          });
        }
      }

      if (this._isNegative(userMessage)) {
        return this._assistantResponse({
          reply: 'D\'accord.',
          question: 'Puis-je vous aider avec autre chose ?',
          options: this._buildAssistantIntentOptions(session.role),
          session,
        });
      }
    }

    if (intent === 'spaces') {
      const requestedDates = this._extractAssistantDateCandidates(userMessage);

      if (requestedDates.length === 0) {
        const todayIso = this._dateToIso(new Date());
        const availabilityToday = await this._buildAssistantAvailabilityAnswer([todayIso]);

        if (!availabilityToday.firstSpace) {
          return this._assistantResponse({
            reply:
              availabilityToday.text ||
              'Aucune disponibilité trouvée pour aujourd\'hui avec les créneaux configurés.',
            question: this._roleSpaceQuestion(session.role),
            options: ['Demain', 'Réserver une salle'],
            session: {
              ...session,
              awaiting: 'space_selection',
              reservation: {
                ...session.reservation,
                date: todayIso,
              },
              availableSpaces: [],
              selectedSpace: null,
              pendingConfirmation: null,
            },
            data: {
              spacesByDate: availabilityToday.spacesByDate,
            },
          });
        }

        const availableSpaces = (availabilityToday.spacesByDate[0]?.spaces || []).map((space) => ({
          ...space,
          date: todayIso,
        }));

        return this._assistantResponse({
          reply: availabilityToday.text,
          question: this._roleSelectionQuestion(session.role),
          options: availableSpaces.slice(0, 6).map((space) => space.name),
          session: {
            ...session,
            awaiting: 'space_selection',
            reservation: {
              ...session.reservation,
              attendees: session.reservation?.attendees || null,
              equipment: Array.isArray(session.reservation?.equipment)
                ? session.reservation.equipment
                : [],
              date: todayIso,
            },
            availableSpaces,
            selectedSpace: null,
            pendingConfirmation: null,
          },
          data: {
            spacesByDate: availabilityToday.spacesByDate,
            spaces: availableSpaces,
          },
        });
      }

      const availability = await this._buildAssistantAvailabilityAnswer(requestedDates);
      if (!availability.firstSpace) {
        return this._assistantResponse({
          reply: availability.text || 'Aucune disponibilité trouvée pour la date demandée.',
          question: 'Souhaitez-vous vérifier une autre date ?',
          options: ['Aujourd\'hui', 'Demain'],
          session: {
            ...session,
            awaiting: 'reservation_date',
            reservation: {
              ...session.reservation,
            },
          },
          data: {
            spacesByDate: availability.spacesByDate,
          },
        });
      }

      const availableSpaces = (availability.spacesByDate.flatMap((group) =>
        (group.spaces || []).map((space) => ({
          ...space,
          date: group.date,
        }))
      )).slice(0, 12);

      return this._assistantResponse({
        reply: availability.text,
        question: this._roleSelectionQuestion(session.role),
        options: availableSpaces.map((space) => space.name),
        session: {
          ...session,
          awaiting: 'space_selection',
          reservation: {
            ...session.reservation,
            date: availability.firstDate,
          },
          availableSpaces,
          selectedSpace: null,
          pendingConfirmation: null,
        },
        data: {
          spacesByDate: availability.spacesByDate,
          spaces: availableSpaces,
        },
      });
    }

    if (intent === 'reservation') {
      return this._assistantResponse({
        reply: `Très bien, je vous accompagne pour la réservation de ${this._roleSpaceLabel(session.role)}.`,
        question: this._roleReservationDateQuestion(session.role),
        options: ['Aujourd\'hui', 'Demain'],
        session: {
          ...session,
          awaiting: 'reservation_date',
          reservation: {},
          pendingConfirmation: null,
        },
      });
    }

    if (intent === 'events') {
      return this._assistantResponse({
        reply: 'Parfait.',
        question: 'Quel type d\'événement vous intéresse ?',
        options: ASSISTANT_EVENT_TYPES,
        session: {
          ...session,
          awaiting: 'event_type',
        },
      });
    }

    if (intent === 'teacher_enrollments') {
      const user = await this._resolveUserOrThrow(context.userId);
      const isTeacherOrAdmin = this._isTeacherRole(user.role) || this._isAdminUserRole(user.role);
      if (!isTeacherOrAdmin) {
        return this._assistantResponse({
          reply:
            'Cette vue des inscriptions est réservée aux profils Enseignant et Admin.',
          question: 'Souhaitez-vous voir les cours publiés ou les espaces disponibles ?',
          options: ['Donner les cours publiés', 'Voir les espaces disponibles'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const enrollments = await this._listAssistantRecentEnrollments({
        instructorId: this._isTeacherRole(user.role) ? user.id : null,
        take: 20,
      });

      if (enrollments.length === 0) {
        return this._assistantResponse({
          reply: this._isTeacherRole(user.role)
            ? 'Aucune inscription étudiante trouvée pour vos cours.'
            : 'Aucune inscription étudiante trouvée actuellement.',
          question: 'Souhaitez-vous consulter les cours publiés ?',
          options: ['Donner les cours publiés', 'Donner les sessions de formation en ligne disponibles'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const list = enrollments
        .map(
          (item) =>
            `• ${item.student} | Cours: ${item.course} | Statut: ${item.status} | Inscrit le: ${item.enrolledAt}`
        )
        .join('\n');

      return this._assistantResponse({
        reply: `Inscriptions étudiantes récentes:\n${list}`,
        question: 'Souhaitez-vous voir aussi les soumissions de devoirs récentes ?',
        options: [
          'Y a-t-il des étudiants qui ont soumis des devoirs ?',
          'Donner les cours publiés',
        ],
        session: {
          ...session,
          awaiting: 'intent',
        },
        data: { enrollments },
      });
    }

    if (intent === 'teacher_submissions') {
      const user = await this._resolveUserOrThrow(context.userId);
      const isTeacherOrAdmin = this._isTeacherRole(user.role) || this._isAdminUserRole(user.role);
      if (!isTeacherOrAdmin) {
        return this._assistantResponse({
          reply:
            'Cette vue des soumissions est réservée aux profils Enseignant et Admin.',
          question: 'Souhaitez-vous voir les devoirs publiés ?',
          options: ['Donner les devoirs publiés', 'Donner les cours publiés'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const submissions = await this._listAssistantRecentSubmissions({
        instructorId: this._isTeacherRole(user.role) ? user.id : null,
        take: 20,
      });

      if (submissions.length === 0) {
        return this._assistantResponse({
          reply: this._isTeacherRole(user.role)
            ? 'Aucune soumission trouvée pour vos devoirs actuellement.'
            : 'Aucune soumission trouvée actuellement.',
          question: 'Souhaitez-vous consulter les devoirs publiés ?',
          options: ['Donner les devoirs publiés', 'Donner les cours publiés'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const list = submissions
        .map(
          (item) =>
            `• ${item.student} | Devoir: ${item.assignment} | Cours: ${item.course} | Soumis le: ${item.submittedAt} | Statut: ${item.status}`
        )
        .join('\n');

      return this._assistantResponse({
        reply: `Soumissions de devoirs récentes:\n${list}`,
        question: 'Souhaitez-vous consulter aussi la liste des étudiants inscrits ?',
        options: [
          'Quelle est la liste des étudiants inscrits à nos cours ?',
          'Donner les devoirs publiés',
        ],
        session: {
          ...session,
          awaiting: 'intent',
        },
        data: { submissions },
      });
    }

    if (intent === 'admin_new_reservations') {
      const user = await this._resolveUserOrThrow(context.userId);
      if (!this._isAdminUserRole(user.role)) {
        return this._assistantResponse({
          reply: 'Cette vue est réservée au profil Admin.',
          question: 'Souhaitez-vous voir vos réservations personnelles ?',
          options: ['Voir les espaces disponibles', 'Réserver une salle équipée'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const reservations = await this._listAssistantReservationsSummary({
        createdToday: true,
        take: 20,
      });

      if (reservations.length === 0) {
        return this._assistantResponse({
          reply: 'Aucune nouvelle réservation créée aujourd\'hui.',
          question: 'Souhaitez-vous afficher les réservations en attente ?',
          options: ['Donner la liste des réservations en attente', 'Voir les espaces disponibles'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const list = reservations
        .map(
          (item) =>
            `• #${item.id} | ${item.space} | Demandeur: ${item.user} | Créneau: ${item.startAt}-${item.endAt} | Statut: ${item.status}`
        )
        .join('\n');

      return this._assistantResponse({
        reply: `Nouvelles réservations du jour:\n${list}`,
        question: 'Souhaitez-vous afficher aussi la liste en attente ?',
        options: ['Donner la liste des réservations en attente', 'Voir les espaces disponibles'],
        session: {
          ...session,
          awaiting: 'intent',
        },
        data: { reservations },
      });
    }

    if (intent === 'admin_pending_reservations') {
      const user = await this._resolveUserOrThrow(context.userId);
      if (!this._isAdminUserRole(user.role)) {
        return this._assistantResponse({
          reply: 'Cette vue est réservée au profil Admin.',
          question: 'Souhaitez-vous voir vos réservations personnelles ?',
          options: ['Voir les espaces disponibles', 'Réserver une salle équipée'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const pendingReservations = await this._listAssistantReservationsSummary({
        status: 'PENDING',
        take: 20,
      });

      if (pendingReservations.length === 0) {
        return this._assistantResponse({
          reply: 'Aucune réservation en attente actuellement.',
          question: 'Souhaitez-vous consulter les nouvelles réservations du jour ?',
          options: ['Quelles sont les nouvelles réservations pour aujourd\'hui ?', 'Voir les espaces disponibles'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const list = pendingReservations
        .map(
          (item) =>
            `• #${item.id} | ${item.space} | Demandeur: ${item.user} | Créneau: ${item.startAt}-${item.endAt} | Créée le: ${item.createdAt}`
        )
        .join('\n');

      return this._assistantResponse({
        reply: `Réservations en attente:\n${list}`,
        question: 'Souhaitez-vous consulter aussi les nouvelles réservations du jour ?',
        options: ['Quelles sont les nouvelles réservations pour aujourd\'hui ?', 'Voir les espaces disponibles'],
        session: {
          ...session,
          awaiting: 'intent',
        },
        data: { pendingReservations },
      });
    }

    if (intent === 'assignments_published' || intent === 'assignments') {
      const assignments = await this._listAssistantPublishedAssignments();

      if (assignments.length === 0) {
        return this._assistantResponse({
          reply: 'Aucun devoir publié disponible pour le moment.',
          question: 'Souhaitez-vous consulter les cours publiés ?',
          options: ['Donner les cours publiés', 'Voir les espaces disponibles'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const list = assignments
        .map(
          (item) =>
            `• ${item.title} | Date limite: ${item.dueDate} | Cours: ${item.courseTitle} | Formateur: ${item.instructor}`
        )
        .join('\n');

      return this._assistantResponse({
        reply: `Devoirs publiés:\n${list}`,
        question: 'Souhaitez-vous aussi voir les cours publiés ou les sessions en ligne ?',
        options: ['Donner les cours publiés', 'Donner les sessions de formation en ligne disponibles'],
        session: {
          ...session,
          awaiting: 'intent',
        },
        data: { assignments },
      });
    }

    if (intent === 'courses_published') {
      const courses = await this._listAssistantPublishedCourses();

      if (courses.length === 0) {
        return this._assistantResponse({
          reply: 'Aucun cours publié disponible pour le moment.',
          question: 'Souhaitez-vous voir les sessions de formation en ligne disponibles ?',
          options: ['Donner les sessions de formation en ligne disponibles', 'Voir les espaces disponibles'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const list = courses
        .map(
          (item) =>
            `• ${item.title} | Niveau: ${item.level} | Formateur: ${item.instructor} | Prochaine session: ${item.nextSession}`
        )
        .join('\n');

      return this._assistantResponse({
        reply: `Cours publiés:\n${list}`,
        question: 'Souhaitez-vous voir les sessions en ligne disponibles ?',
        options: ['Donner les sessions de formation en ligne disponibles', 'Voir les espaces disponibles'],
        session: {
          ...session,
          awaiting: 'intent',
        },
        data: { courses },
      });
    }

    if (intent === 'online_sessions') {
      const sessions = await this._listAssistantOnlineSessions();

      if (sessions.length === 0) {
        return this._assistantResponse({
          reply: 'Aucune session de formation en ligne disponible actuellement.',
          question: 'Souhaitez-vous voir les cours publiés ?',
          options: ['Donner les cours publiés', 'Voir les espaces disponibles'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const list = sessions
        .map(
          (item) =>
            `• ${item.title} | Cours: ${item.courseTitle} | Formateur: ${item.instructor} | Date: ${item.startDate} | Statut: ${item.status}`
        )
        .join('\n');

      return this._assistantResponse({
        reply: `Sessions de formation en ligne disponibles:\n${list}`,
        question: 'Souhaitez-vous consulter aussi les cours publiés ?',
        options: ['Donner les cours publiés', 'Voir les espaces disponibles'],
        session: {
          ...session,
          awaiting: 'intent',
        },
        data: { sessions },
      });
    }

    if (intent === 'published_sessions') {
      const user = await this._resolveUserOrThrow(context.userId);
      const sessions = await this._listAssistantPublishedTeacherSessions({
        instructorId: this._isTeacherRole(user.role) ? user.id : null,
        take: 12,
      });

      if (sessions.length === 0) {
        return this._assistantResponse({
          reply: this._isTeacherRole(user.role)
            ? 'Aucune session publiée pour vos cours actuellement.'
            : 'Aucune session publiée par les enseignants actuellement.',
          question: 'Souhaitez-vous voir les cours publiés ?',
          options: ['Donner les cours publiés', 'Voir les espaces disponibles'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const list = sessions
        .map(
          (item) =>
            `• ${item.title} | Cours: ${item.courseTitle} | Enseignant: ${item.instructor} | Type: ${item.type} | Date: ${item.startDate} | Statut: ${item.status}`
        )
        .join('\n');

      return this._assistantResponse({
        reply: `Sessions publiées par les enseignants:\n${list}`,
        question: 'Souhaitez-vous voir aussi les cours publiés ?',
        options: ['Donner les cours publiés', 'Donner les sessions de formation en ligne disponibles'],
        session: {
          ...session,
          awaiting: 'intent',
        },
        data: { sessions },
      });
    }

    if (intent === 'formations') {
      const courses = await this._listAssistantPublishedCourses();

      if (courses.length === 0) {
        return this._assistantResponse({
          reply: 'Aucune formation publiée disponible pour le moment.',
          question: 'Souhaitez-vous voir les sessions en ligne disponibles ?',
          options: ['Donner les sessions de formation en ligne disponibles', 'Voir les espaces disponibles'],
          session: {
            ...session,
            awaiting: 'intent',
          },
        });
      }

      const list = courses
        .map(
          (item) =>
            `• ${item.title} | Niveau: ${item.level} | Formateur: ${item.instructor} | Prochaine session: ${item.nextSession}`
        )
        .join('\n');

      return this._assistantResponse({
        reply: `Formations publiées:\n${list}`,
        question: 'Puis-je vous aider avec autre chose ?',
        options: this._buildAssistantIntentOptions(session.role),
        session: {
          ...session,
          awaiting: 'intent',
        },
        data: { courses },
      });
    }

    if (intent === 'assignments' && session.role === ASSISTANT_ROLES.ETUDIANT) {
      return this._assistantResponse({
        reply:
          'Pour voir les devoirs disponibles, ouvrez le module Devoirs dans votre espace étudiant.',
        question: 'Puis-je vous aider avec autre chose ?',
        session: {
          ...session,
          awaiting: 'intent',
        },
      });
    }

    if (this._isAffirmative(userMessage) || this._isNegative(userMessage)) {
      return this._assistantResponse({
        reply: 'Cette demande dépasse mes fonctionnalités actuelles. Souhaitez-vous contacter notre équipe ?',
        options: ['Oui', 'Non'],
        session: {
          ...session,
          awaiting: 'intent',
        },
      });
    }

    return this._assistantResponse({
      reply: 'Cette demande dépasse mes fonctionnalités actuelles. Souhaitez-vous contacter notre équipe ?',
      options: ['Oui', 'Non', ...this._buildAssistantIntentOptions(session.role)],
      session: {
        ...session,
        awaiting: 'intent',
      },
    });
  }
}

module.exports = new CommunicationService();
