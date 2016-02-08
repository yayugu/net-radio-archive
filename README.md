# ねとらじあーかいぶ
Net Radio Archive

## なにこれ
ネットラジオを録画するやつ

今のところ対応しているラジオ

- Radiko
- 超A&G+
- 響
- 音泉
- アニたま
- AG-ON

## 特徴
「全部の番組」を取ります。

大抵の録画ソフトは時間していで録ったりしますがそうじゃない。

今ブレイクしてる新人声優の2年前のラジオ番組を掘り起こしたい!
あと新番組を取り逃す心配がなかったり、ザッピングしていると意外とおもしろいラジオ発掘したりできて便利。

## 必要なもの
- 常時起動しているマシン
- LinuxなどUNIX的なOS (Windowsでも動かしたい...)
- Ruby 2.0 or higher
- rtmpdump
- swftools
- あたらしめのffmpeg (HTTP Live Streaming の input に対応しているもの)
 - ※最新のffmpegの導入は面倒であることが多いです。自分はLinuxではstatic buildを使っています。 http://qiita.com/yayugu/items/d7f6a15a6f988064f51c
 - Macではhomebrewで導入できるバージョンで問題ありません
- (AG-ONのみ)
 - GUI環境 or xvfb
 - firefox

## セットアップ

```
# 必要なライブラリをインストール
# Ubuntuの場合:
$ sudo apt-get install rtmpdump swftools ruby

$ # libavがインストールされている場合には削除してから
$ wget http://johnvansickle.com/ffmpeg/releases/ffmpeg-release-64bit-static.tar.xz
$ tar xvf ffmpeg-release-64bit-static.tar.xz
$ sudo cp ./ffmpeg-release-64bit-static/ffmpeg /usr/local/bin

$ git clone https://github.com/yayugu/net-radio-archive.git
$ cd net-radio-archive
$ git submodule update --init --recursive
$ (sudo) gem install bundler
$ bundle install --without development test
$ # AG-ONを使用しない場合は `agon` も加えることでSeleniumのインストールをスキップできます
$ cp config/database.example.yml config/database.yml
$ cp config/settings.example.yml config/settings.yml
$ vi config/database.yml # 各自の環境に合わせて編集
$ vi config/settings.yml # 各自の環境に合わせて編集

# サーバー内での手動設定 (お手軽、自分はこれでやってます)
$ RAILS_ENV=production bundle exec rake db:create db:migrate
$ RAILS_ENV=production bundle exec whenever --update-crontab
$ # (または) RAILS_ENV=production bundle exec whenever -u $YOUR-USERNAME --update-crontab

# アップデート
$ git pull origin master
$ git submodule update --init --recursive
$ bundle install --without development test
$ RAILS_ENV=production bundle exec rake db:migrate
$ RAILS_ENV=production bundle exec whenever --update-crontab

# capistranoでのデプロイ設定
$ cp config/deploy/production.example.rb config/deploy/production.rb
$ vi config/deploy/production.rb # 各自の環境に合わせて編集
$ bundle exec cap production deploy
```

cronに
`MAILTO='your-mail-address@foo.com'`
のように記述してエラーが起きた時に検知しやすくしておくと便利です。

## FAQ

### Q. 使い方でわからないところある
A. Githubでissueつくってください。

### Q. ◯◯に対応してほしい
A. Githubでissueつくってください。あとpull req募集中

### Q. radikoがうまく動かない
A. Radikoはアクセスする側のIPによってどの局を聴けるかが変わります。
ブラウザで開いてみたり、以下のページなどを参考にご自身が聞ける局をsettings.ymlに設定してください。

http://d.hatena.ne.jp/zariganitosh/20130214/radiko_keyword_preset

### Q. AG-ONをうまく動かせない
A. 難しいです。Githubでissueつくっていただければ相談にのりますのでお気軽にどうぞ。
もしくはSeleniumを使わないように修正していただけるpull req募集中

### Q. rtmpdumpが不安定 / CPUを100%消費する
gitで最新のソースを取得してきてビルドすると改善することが多いです。

http://qiita.com/yayugu/items/12c0ffd92bc8539098b8

### Q. 録画がはじまらない / 特定のプラットフォーム or 局のみ録画がはじまらない
番組表の取得がまだ行われていない可能性があります。 config/schedule.rbを見ていただけるとわかるのですが番組表の取得は昼間中心となっています。お急ぎの場合は手動で

```
$ RAILS_ENV=production bundle exec rake main:XXXX_scrape
```

を実行してください

