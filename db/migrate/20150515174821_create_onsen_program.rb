class CreateOnsenProgram < ActiveRecord::Migration
  def up
    sql = <<EOF
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
EOF
    ActiveRecord::Base.connection.execute(sql)
  end
  def down
    sql = 'DROP TABLE `onsen_programs`;'
    ActiveRecord::Base.connection.execute(sql)
  end
end
