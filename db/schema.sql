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

CREATE TABLE `onsen_programs` (
    `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `number` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
    `date` datetime NOT NULL,
    `file_url` varchar(767) CHARACTER SET ASCII NOT NULL,
    `personality` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `state` varchar(100) CHARACTER SET ASCII NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`file_url`)
);

CREATE TABLE `hibiki_programs` (
    `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `comment` varchar(150) CHARACTER SET utf8mb4 NOT NULL,
    `rtmp_url` varchar(767) CHARACTER SET ASCII NOT NULL,
    `state` varchar(100) CHARACTER SET ASCII NOT NULL,
    `retry_count` int UNSIGNED NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`rtmp_url`)
);
