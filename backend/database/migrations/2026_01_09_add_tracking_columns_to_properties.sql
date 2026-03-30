-- Migration to add tracking columns to properties table
-- Generated: 2026-01-09

ALTER TABLE `properties`
ADD COLUMN `view_count` INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Number of times property details viewed',
ADD COLUMN `inspection_booking_count` INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Number of times property booked for inspection',
ADD COLUMN `leads_count` INT(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Number of times property saved (leads generated)';
