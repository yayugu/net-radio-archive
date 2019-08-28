# ねとらじあーかいぶ
Net Radio Archive

## なにこれ
ネットラジオを録画するやつ

今のところ対応しているラジオ

- Radiko (エリアフリーも対応)
- 超A&G+
- 響
- 音泉
- AG-ON Premium
- らじる(NHK)
- ニコ生（ニコニコ生放送）

## 特徴
「全部の番組」を取ります。

大抵の録画ソフトは時間していで録ったりしますがそうじゃない。

今ブレイクしてる新人声優の2年前のラジオ番組を掘り起こしたい!
あと新番組を取り逃す心配がなかったり、ザッピングしていると意外とおもしろいラジオ発掘したりできて便利。

## 必要なもの
- 常時起動しているマシン
- LinuxなどUNIX的なOS
  - WindowsでもBash on Windows / Windows Subsystem for Linuxなら動きますがcronに依存しており、WSLではcronを動かすのが少し手間です
- Ruby 2.4 or later
- rtmpdump
- swftools
- あたらしめのffmpeg (HTTP Live Streaming の input に対応しているもの)
  - ※最新のffmpegの導入は面倒であることが多いです。自分はLinuxではstatic buildを使っています。 http://qiita.com/yayugu/items/d7f6a15a6f988064f51c
  - Macではhomebrewで導入できるバージョンで問題ありません
- livedl
- (ラジコエリアフリー利用者のみ)
  - ラジコプレミアム会員のアカウント
- (AG-ON Premiumのみ)
  - AG-ON Premiumのアカウント
- (ニコ生のみ)
  - プレミアム会員のアカウント

## セットアップ

### ふつうにセットアップ
```
# 必要なライブラリをインストール
# Ubuntuの場合:
$ # Mysqlは5.6以外でも可
$ # Ubuntu 14.04だとrubyのversionが古いのでお好きな方法orこの辺(https://www.brightbox.com/blog/2016/01/06/ruby-2-3-ubuntu-packages/ ) を参考に新しめなバージョンをインストールしてください
$ sudo apt-get install rtmpdump swftools ruby git mysql-server-5.6 mysql-client-5.6 libmysqld-dev
$ sudo service mysql start # WSLだとっぽい表示がでるかもしれませんがプロセスが起動していればOK

$ # libavがインストールされている場合には削除してから
$ wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
$ tar xvf ffmpeg-release-amd64-static.tar.xz
$ sudo cp ./ffmpeg-release-amd64-static/ffmpeg /usr/local/bin

$ wget https://github.com/yayugu/livedl/releases/download/20181107.38/livedl
$ sudo cp ./livedl /usr/local/bin/livedl
$ sudo chmod +x /usr/local/bin/livedl
# 取得したコンパイル済みバイナリが正常に動かない場合は、ここから(https://github.com/himananiito/livedl)ソースを取得して自前でコンパイルし、上記パスにインストールする

$ git clone https://github.com/yayugu/net-radio-archive.git
$ cd net-radio-archive
$ (sudo) gem install bundler
$ bundle install --without development test agon
$ cp config/database.example.yml config/database.yml
$ cp config/settings.example.yml config/settings.yml
$ vi config/database.yml # 各自の環境に合わせて編集
$ vi config/settings.yml # 各自の環境に合わせて編集
$ RAILS_ENV=production bundle exec rake db:create db:migrate
$ RAILS_ENV=production bundle exec whenever --update-crontab
$ # (または) RAILS_ENV=production bundle exec whenever -u $YOUR-USERNAME --update-crontab

# アップデート
$ git pull origin master
$ git submodule update --init --recursive
$ bundle install --without development test agon
$ RAILS_ENV=production bundle exec rake db:migrate
$ RAILS_ENV=production bundle exec whenever --update-crontab
```

cronに
`MAILTO='your-mail-address@foo.com'`
のように記述してエラーが起きた時に検知しやすくしておくと便利です。


### Dockerでセットアップ
Dockerの知識がある程度必要ですがわかっていれば楽です。

まずMySQLサーバーを用意してください。
ローカル用意してもdocker-composeとかで建ててもなんでもいいです
そしてDockerコンテナからそのMySQLに疎通できるようにしておいてください

```
$ git clone https://github.com/yayugu/net-radio-archive.git
$ cd net-radio-archive

$ cp config/database.example.yml config/database.yml
$ cp config/settings.example.yml config/settings.yml
$ vi config/database.yml # 各自の環境に合わせて編集
$ vi config/settings.yml # 各自の環境に合わせて編集

$ docker build --network host -t yayugu/net-radio-archive .

# 起動
# いくつかのディレクトリはホストのものを使うことを推奨しています
# /working : 作業用ディレクトリです。それなりに容量を消費します
# /archive : 録画したファイルが置かれるディレクトリです。大事
# /myapp/log : ログが置かれるディレクトリです
$ docker run -d --rm --network host \
  -v /host/path/to/working/dir:/working \
  -v /host/path/to/archive/dir:/archive \
  -v /host/path/to/log:/myapp/log \
  yayugu/net-radio-archive

# 長期運用する場合はlogrotateを入れておきましょう
$ cat /etc/logrotate.d/net-radio-archive
/host/path/to/log/*.log {
    daily
    missingok
    rotate 7
    notifempty
    copytruncate
}
```

## FAQ

### Q. 使い方でわからないところある
A. Githubでissueつくってください。

### Q. ◯◯に対応してほしい
A. Githubでissueつくってください。あとpull req募集中

### Q. radikoがうまく動かない
A. Radikoはアクセスする側のIPによってどの局を聴けるかが変わります。
ブラウザで開いてみたり、以下のページなどを参考にご自身が聞ける局をsettings.ymlに設定してください。

http://d.hatena.ne.jp/zariganitosh/20130214/radiko_keyword_preset

またプレミアム会員になることでエリアフリーですべての局を聴取することができます。
ご自身のIPが希望する局のエリア外の場合にはラジコプレミアムに加入してradiko_premiumの設定を試してみてください

### Q. AG-ON Premiumで有料コンテンツを録画できない
自分が契約している月額コンテンツがないため、検証ができていません。
そのため録画リストへの追加を行わないようにしています

対応してくれるpull reqを募集しております

### Q. rtmpdumpが不安定 / CPUを100%消費する
gitで最新のソースを取得してきてビルドすると改善することが多いです。

http://qiita.com/yayugu/items/12c0ffd92bc8539098b8

### Q. 録画がはじまらない / 特定のプラットフォーム or 局のみ録画がはじまらない
番組表の取得がまだ行われていない可能性があります。 config/schedule.rbを見ていただけるとわかるのですが番組表の取得は昼間中心となっています。お急ぎの場合は手動で

```
$ RAILS_ENV=production bundle exec rake main:XXXX_scrape
```

を実行してください

### Q. ニコ生の動作がいまいち
ニコ生については色々制約が多いです
- プレミアム会員必須
- タイムシフトから取得するためタイムシフトに対応していない番組は対応不可
- コメントはいまのところ取得できない
- さまざまな理由でダウンロードに失敗することがある

改善のpull reqお待ちしております
