class CreateNiconicoVideoPrograms < ActiveRecord::Migration
  def up
    sql = <<EOF
CREATE TABLE `niconico_video_programs` (
    `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
    `video_id` varchar(250) CHARACTER SET ASCII NOT NULL,
    `title` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `state` varchar(100) CHARACTER SET ASCII NOT NULL,
    `retry_count` int UNSIGNED NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`video_id`)
);
EOF
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
    sql = 'DROP TABLE `niconico_video_programs`;'
    ActiveRecord::Base.connection.execute(sql)
  end
end
