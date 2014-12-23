CREATE TABLE `jobs` (
    `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
    `ch` varchar(100) CHARACTER SET ASCII NOT NULL,
    `start` datetime NOT NULL,
    `end` datetime NOT NULL,
    `title` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `state` varchar(100) CHARACTER SET ASCII NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`),
    INDEX start_index (`ch`, `start`, `state`),
    INDEX end_index (`ch`, `end`, `state`)
);
