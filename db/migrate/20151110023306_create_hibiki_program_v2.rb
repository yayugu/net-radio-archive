class CreateHibikiProgramV2 < ActiveRecord::Migration
  def up
    sql = <<EOF
CREATE TABLE `hibiki_program_v2s` (
    `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
    `access_id` varchar(100) CHARACTER SET ASCII NOT NULL,
    `episode_id` int UNSIGNED NOT NULL,
    `title` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `episode_name` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `cast` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `state` varchar(100) CHARACTER SET ASCII NOT NULL,
    `retry_count` int UNSIGNED NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`access_id`, `episode_id`)
);
EOF
    ActiveRecord::Base.connection.execute(sql)
  end
  def down
    sql = 'DROP TABLE `hibiki_program_v2s`;'
    ActiveRecord::Base.connection.execute(sql)
  end
end
