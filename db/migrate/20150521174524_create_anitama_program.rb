class CreateAnitamaProgram < ActiveRecord::Migration
  def up
    # book_id がUNIQUEになることに確信を持てないのでこういう設計に
    sql = <<EOF
CREATE TABLE `anitama_programs` (
    `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
    `book_id` varchar(250) CHARACTER SET ASCII NOT NULL,
    `title` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `update_time` datetime NOT NULL,
    `state` varchar(100) CHARACTER SET ASCII NOT NULL,
    `retry_count` int UNSIGNED NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`book_id`, `update_time`)
);
EOF
    ActiveRecord::Base.connection.execute(sql)
  end
  def down
    sql = 'DROP TABLE `anitama_programs`;'
    ActiveRecord::Base.connection.execute(sql)
  end
end
