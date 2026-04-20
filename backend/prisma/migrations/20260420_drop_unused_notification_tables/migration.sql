-- Drop unused notification tables that are no longer referenced by the Prisma schema or backend code
DROP TABLE IF EXISTS `NotificationSchedule`;
DROP TABLE IF EXISTS `FCMToken`;
