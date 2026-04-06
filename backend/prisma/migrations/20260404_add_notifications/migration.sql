/*
  Warnings:

  - You are about to drop a column `mystatus` on the `notification` table. All the data in that column will be lost.

*/
-- CreateTable FCMToken
CREATE TABLE IF NOT EXISTS `FCMToken` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `userId` INT NOT NULL,
    `token` LONGTEXT NOT NULL,
    `device` VARCHAR(255),
    `isActive` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `FCMToken_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User` (`id`) ON DELETE CASCADE,
    UNIQUE KEY `FCMToken_userId_token_key` (`userId`, `token`(100))
);

-- CreateTable Notification
CREATE TABLE IF NOT EXISTS `Notification` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `userId` INT NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `body` LONGTEXT NOT NULL,
    `data` JSON,
    `isRead` BOOLEAN NOT NULL DEFAULT false,
    `isSent` BOOLEAN NOT NULL DEFAULT false,
    `sentAt` TIMESTAMP NULL,
    `readAt` TIMESTAMP NULL,
    `reservationId` INT,
    `courseId` INT,
    `sessionId` INT,
    `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `Notification_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User` (`id`) ON DELETE CASCADE,
    CONSTRAINT `Notification_reservationId_fkey` FOREIGN KEY (`reservationId`) REFERENCES `Reservation` (`id`) ON DELETE SET NULL,
    CONSTRAINT `Notification_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course` (`id`) ON DELETE SET NULL,
    CONSTRAINT `Notification_sessionId_fkey` FOREIGN KEY (`sessionId`) REFERENCES `TrainingSession` (`id`) ON DELETE SET NULL,
    INDEX `Notification_userId_idx` (`userId`)
);

-- CreateTable NotificationSchedule
CREATE TABLE IF NOT EXISTS `NotificationSchedule` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `notificationId` INT NOT NULL,
    `scheduledFor` TIMESTAMP NOT NULL,
    `sent` BOOLEAN NOT NULL DEFAULT false,
    `failureReason` TEXT,
    `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `NotificationSchedule_notificationId_fkey` FOREIGN KEY (`notificationId`) REFERENCES `Notification` (`id`) ON DELETE CASCADE,
    INDEX `NotificationSchedule_scheduledFor_idx` (`scheduledFor`),
    INDEX `NotificationSchedule_sent_idx` (`sent`),
    INDEX `NotificationSchedule_notificationId_idx` (`notificationId`)
);
