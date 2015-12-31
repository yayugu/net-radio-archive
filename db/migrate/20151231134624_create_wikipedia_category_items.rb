class CreateWikipediaCategoryItems < ActiveRecord::Migration
  def up
    # 検索用キーワードとして抽出するため
    # あまり長いワードは取得できても意味がないためvarcharの長さ制限は短めに
    sql = <<EOF
CREATE TABLE `wikipedia_category_items` (
    `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
    `category` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
    `title` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`category`, `title`)
);
EOF
    ActiveRecord::Base.connection.execute(sql)
  end
  def down
    sql = 'DROP TABLE `wikipedia_category_items`;'
    ActiveRecord::Base.connection.execute(sql)
  end
end
