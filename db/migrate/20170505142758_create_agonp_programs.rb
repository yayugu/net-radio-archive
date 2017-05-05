class CreateAgonpPrograms < ActiveRecord::Migration
  def up
    sql = <<EOF
CREATE TABLE `agonp_programs` (
    `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `personality` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `episode_id` varchar(250) CHARACTER SET ASCII NOT NULL,
    `price` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
    `state` varchar(100) CHARACTER SET ASCII NOT NULL,
    `retry_count` int UNSIGNED NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`episode_id`)
);
EOF
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
    sql = 'DROP TABLE `agonp_programs`;'
    ActiveRecord::Base.connection.execute(sql)
  end
end
