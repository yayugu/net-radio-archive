class AddColumnOnsenRetry < ActiveRecord::Migration
  def up
    sql = <<EOF
ALTER TABLE `onsen_programs`
ADD COLUMN `retry_count` int UNSIGNED NOT NULL
AFTER `state`
EOF
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
  end
end
