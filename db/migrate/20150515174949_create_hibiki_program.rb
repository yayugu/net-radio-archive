class CreateHibikiProgram < ActiveRecord::Migration
  def up
    sql = <<EOF
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
EOF
    ActiveRecord::Base.connection.execute(sql)
  end
  def down
    sql = 'DROP TABLE `hibiki_programs`;'
    ActiveRecord::Base.connection.execute(sql)
  end
end
