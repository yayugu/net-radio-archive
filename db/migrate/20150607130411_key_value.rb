class KeyValue < ActiveRecord::Migration
  def up
    sql = <<EOF
CREATE TABLE `key_value` (
    `key` varchar(256) CHARACTER SET ASCII NOT NULL,
    `value` varchar(250) CHARACTER SET utf8mb4 NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`key`)
);
EOF
    ActiveRecord::Base.connection.execute(sql)
  end
  def down
    sql = 'DROP TABLE `key_value`;'
    ActiveRecord::Base.connection.execute(sql)
  end
end
