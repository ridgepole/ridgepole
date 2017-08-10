USE `ridgepole_test`;

DROP TABLE IF EXISTS `clubs`;
CREATE TABLE `clubs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_name` (`name`)
);

DROP TABLE IF EXISTS `places`;
CREATE TABLE `places` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `location` geometry NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id` (`id`)
);
