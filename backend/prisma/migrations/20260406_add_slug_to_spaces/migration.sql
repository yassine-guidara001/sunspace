-- Add slug field to Space table
ALTER TABLE `Space` ADD COLUMN `slug` VARCHAR(100);

-- Create unique index on slug
CREATE UNIQUE INDEX `Space_slug_key` ON `Space`(`slug`);

-- Populate slug values based on ID if slug is null
UPDATE `Space` SET `slug` = CONCAT('espace', CAST(id AS CHAR)) WHERE `slug` IS NULL;

-- Make slug NOT NULL
ALTER TABLE `Space` MODIFY `slug` VARCHAR(100) NOT NULL;
