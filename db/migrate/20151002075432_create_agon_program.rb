class CreateAgonProgram < ActiveRecord::Migration
  def up
    sql = <<EOF
CREATE TABLE `agon_programs` (
    `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `personality` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `episode_id` varchar(250) CHARACTER SET ASCII NOT NULL,
    `page_url` varchar(767) CHARACTER SET ASCII NOT NULL,
    `state` varchar(100) CHARACTER SET ASCII NOT NULL,
    `retry_count` int UNSIGNED NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`episode_id`),
    KEY (`page_url`)
);
EOF
    ActiveRecord::Base.connection.execute(sql)
  end
  def down
    sql = 'DROP TABLE `agon_programs`;'
    ActiveRecord::Base.connection.execute(sql)
  end
end
