# ねとらじあーかいぶ
Net Radio Archive

## なにこれ
ネットラジオを録画するやつ

今のところ対応しているラジオ

- Radiko
- 超A&G+
- 響
- 音泉

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
- ffmpeg
- swftools

## セットアップ

```
# 必要なライブラリをインストール
# Ubuntuの場合:
$ sudo apt-get install rtmpdump ffmpeg swftools ruby

$ git clone https://github.com/yayugu/net-radio-archive.git
$ cd net-radio-archive
$ (sudo) gem install bundler
$ bundle install
$ cp config/database.example.yml config/database.yml
$ cp config/settings.example.yml config/settings.yml
$ vi config/database.yml # 各自の環境に合わせて編集
$ vi config/settings.yml # 各自の環境に合わせて編集

$ RAILS_ENV=production bundle exec rake db:create db:migrate
$ bundle exec whenever --update-crontab
# (または) bundle exec whenever -u $YOUR-USERNAME --update-crontab
```

cronに
`MAILTO='your-mail-address@foo.com'`
のように記述してエラーが起きた時に検知しやすくしておくと便利です。

## FAQ

### Q. 使い方でわからないところある
A. Githubでissueつくってください。

### Q. ◯◯に対応してねえぞ
A. Githubでissueつくってください。あとpull req募集中

### Q. radikoがうまく動かない
A. Radikoはアクセスする側のIPによってどの局を聴けるかが変わります。
ブラウザで開いてみたり、以下のページなどを参考にご自身が聞ける局をsettings.ymlに設定してください。

http://d.hatena.ne.jp/zariganitosh/20130214/radiko_keyword_preset
