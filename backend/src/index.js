require('dotenv').config();
const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

// Middleware
const errorHandler = require('./middleware/errorHandler');
const { requestLogger } = require('./middleware/logger');

// Routes
const authRoutes = require('./routes/auth.routes');
const usersRoutes = require('./routes/users.routes');
const spacesRoutes = require('./routes/spaces.routes');
const equipmentRoutes = require('./routes/equipment.routes');
const associationsRoutes = require('./routes/associations.routes');
const coursesRoutes = require('./routes/courses.routes');
const trainingSessionsRoutes = require('./routes/trainingSessions.routes');
const assignmentsRoutes = require('./routes/assignments.routes');
const submissionsRoutes = require('./routes/submissions.routes');
const enrollmentsRoutes = require('./routes/enrollments.routes');
const uploadRoutes = require('./routes/upload.routes');
const reservationsRoutes = require('./routes/reservations.routes');
const notificationsRoutes = require('./routes/notifications.routes');
const notificationsService = require('./services/notifications.service');

const app = express();
const isDevelopment = (process.env.NODE_ENV || 'development') === 'development';

// ============ HEADER SECURITY ============
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// ============ CORS MIDDLEWARE (FIRST!) ============
// En développement: accepter toutes les origins
if (process.env.NODE_ENV === 'development') {
  app.use(cors({
    origin: true, // Accepter toutes les origins
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'Accept',
      'Origin',
    ],
    optionsSuccessStatus: 200,
  }));
  
  // Gérer les requêtes preflight manuellement si nécessaire
  app.options('*', cors({
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'Accept',
      'Origin',
    ],
    optionsSuccessStatus: 200,
  }));
} else {
  // En production: limiter aux origins autorisées
  const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:3000')
    .split(',')
    .map(o => o.trim());

  const localhostPattern = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;
  const isAllowedOrigin = (origin) => {
    if (!origin) return true;
    if (allowedOrigins.includes(origin)) return true;
    return localhostPattern.test(origin);
  };
  
  app.use(cors({
    origin: (origin, callback) => {
      if (isAllowedOrigin(origin)) {
        callback(null, true);
      } else {
        console.warn(`❌ CORS blocked: ${origin}`);
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'Accept',
      'Origin',
    ],
    optionsSuccessStatus: 200,
  }));

  app.options('*', cors({
    origin: (origin, callback) => {
      if (isAllowedOrigin(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'Accept',
      'Origin',
    ],
    optionsSuccessStatus: 200,
  }));
}

// Rate limiting
const globalLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || String(15 * 60 * 1000), 10),
  max: parseInt(process.env.RATE_LIMIT_MAX || (isDevelopment ? '5000' : '300'), 10),
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => req.method === 'OPTIONS',
  message: 'Trop de requêtes, réessayez plus tard.',
});

const loginLimiter = rateLimit({
  windowMs: parseInt(process.env.LOGIN_RATE_LIMIT_WINDOW_MS || String(15 * 60 * 1000), 10),
  max: parseInt(process.env.LOGIN_RATE_LIMIT_MAX || (isDevelopment ? '100' : '10'), 10),
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => req.method === 'OPTIONS',
  message: 'Trop de tentatives de connexion, réessayez dans 15 minutes.',
});

const enableDevGlobalLimiter = String(process.env.ENABLE_DEV_RATE_LIMIT || 'false').toLowerCase() === 'true';
if (!isDevelopment || enableDevGlobalLimiter) {
  app.use(globalLimiter);
}

// ============ BODY PARSERS ============
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// ============ LOGGING ============
app.use(morgan(':method :url :status :response-time ms'));
app.use(requestLogger);

// ============ HEALTH CHECK ============
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.get('/api', (req, res) => {
  res.json({
    message: 'Sunspace API v1.0.0',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
    },
  });
});

// ============ ROUTES ============
app.use('/api/auth', loginLimiter, authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/spaces', spacesRoutes);
app.use('/api/equipment-assets', equipmentRoutes);
app.use('/api/equipments', equipmentRoutes);
app.use('/api/associations', associationsRoutes);
app.use('/api/courses', coursesRoutes);
app.use('/api/training-sessions', trainingSessionsRoutes);
app.use('/api/sessions', trainingSessionsRoutes);
app.use('/api/assignments', assignmentsRoutes);
app.use('/api/submissions', submissionsRoutes);
app.use('/api/enrollments', enrollmentsRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/reservations', reservationsRoutes);
app.use('/api/notifications', notificationsRoutes);

// ============ 404 HANDLER ============
app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.path,
    method: req.method,
  });
});

// ============ ERROR HANDLER ============
app.use(errorHandler);

// ============ START SERVER ============
const PORT = process.env.PORT || 3001;
const NODE_ENV = process.env.NODE_ENV || 'development';
const REMINDER_INTERVAL_MS = 5 * 60 * 1000;

app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════╗
║  🚀 Sunspace Backend                               ║
║  Port: ${PORT}                                      ║
║  Environment: ${NODE_ENV}                          ║
║  Database: MySQL (Prisma)                          ║
║  Auth: JWT                                         ║
╚════════════════════════════════════════════════════╝
  `);

  const runReminderPass = async () => {
    try {
      const result = await notificationsService.processDueReservationReminders();
      if (result.totalCreated > 0) {
        console.log(
          `[notifications] reminders sent: 24h=${result.created24h}, 1h=${result.created1h}`
        );
      }
    } catch (error) {
      console.error('[notifications] reminder job failed:', error.message);
    }
  };

  const runNotificationBackfill = async () => {
    try {
      const result = await notificationsService.backfillMissingReservationConfirmations();
      if (result.created > 0) {
        console.log(`[notifications] confirmation backfill created=${result.created}`);
      }
    } catch (error) {
      console.error('[notifications] confirmation backfill failed:', error.message);
    }
  };

  setTimeout(runNotificationBackfill, 2000);
  setTimeout(runReminderPass, 8000);
  setInterval(runReminderPass, REMINDER_INTERVAL_MS);
});

module.exports = app;
