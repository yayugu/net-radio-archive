CREATE TABLE `jobs` (
    `id` int NOT NULL AUTO_INCREMENT,
    `start` datetime NOT NULL,
    `end` datetime NOT NULL,
    `title` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `state` varchar(100) CHARACTER SET ASCII NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`)
);
