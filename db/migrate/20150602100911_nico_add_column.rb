class NicoAddColumn < ActiveRecord::Migration
  def up
    sql = <<EOF
ALTER TABLE `niconico_live_programs`
ADD COLUMN `cannot_recovery` boolean NOT NULL
AFTER `state`
EOF
    ActiveRecord::Base.connection.execute(sql)

    sql = <<EOF
ALTER TABLE `niconico_live_programs`
ADD COLUMN `memo` text CHARACTER SET utf8mb4 NOT NULL
AFTER `cannot_recovery`
EOF
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
  end
end
