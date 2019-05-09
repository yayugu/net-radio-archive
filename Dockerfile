FROM buildpack-deps:xenial

#============
# Packages
#============
RUN  echo "deb http://archive.ubuntu.com/ubuntu xenial main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu xenial-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu xenial-security main universe\n" >> /etc/apt/sources.list
RUN apt-get update -qqy \
  && apt-get install -y --no-install-recommends nodejs swftools git xvfb wget bzip2 ca-certificates tzdata sudo unzip cron locales \
    rsyslog \
    coreutils
# rsyslog: for get cron error logs
# coreutils: for sleep command

#=========
# Ruby
# see Dockerfiles on https://hub.docker.com/_/ruby/
#=========
# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
	&& { \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.4
ENV RUBY_VERSION 2.4.2
ENV RUBYGEMS_VERSION 2.7.2

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
RUN set -ex \
	&& buildDeps=' \
		bison \
		libgdbm-dev \
		ruby \
	' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& rm -rf /var/lib/apt/lists/* \
	&& wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" \
	&& mkdir -p /usr/src/ruby \
	&& tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 \
	&& rm ruby.tar.xz \
	&& cd /usr/src/ruby \
	&& { \
		echo '#define ENABLE_PATH_CHECK 0'; \
		echo; \
		cat file.c; \
	} > file.c.new \
	&& mv file.c.new file.c \
	&& autoconf \
	&& ./configure --disable-install-doc --enable-shared \
	&& make -j"$(nproc)" \
	&& make install \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& cd / \
	&& rm -r /usr/src/ruby

ENV BUNDLER_VERSION 1.16.0

RUN gem install bundler --version "$BUNDLER_VERSION"

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
	BUNDLE_BIN="$GEM_HOME/bin" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
	&& chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

#=========
# ffmpeg
#=========
RUN wget --no-verbose -O /tmp/ffmpeg.tar.gz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz \
  && tar -C /tmp -xf /tmp/ffmpeg.tar.gz \
  && mv /tmp/ffmpeg-*-amd64-static/ffmpeg /usr/bin \
  && rm -rf /tmp/ffmpeg*

#=========
# rtmpdump
#=========
RUN git clone git://git.ffmpeg.org/rtmpdump \
  && cd /rtmpdump \
  && make \
  && make install

#=========
# youtube-dl
#=========
RUN wget https://yt-dl.org/downloads/latest/youtube-dl -O /usr/local/bin/youtube-dl && chmod a+rx /usr/local/bin/youtube-dl

#=========
# livedl
#=========
RUN wget https://github.com/yayugu/livedl/releases/download/20181107.38/livedl -O /usr/local/bin/livedl \
  && chmod a+rx /usr/local/bin/livedl

#============
# Timezone
# see: https://bugs.launchpad.net/ubuntu/+source/tzdata/+bug/1554806
#============
ENV TZ "Asia/Tokyo"
RUN echo 'Asia/Tokyo' > /etc/timezone \
  && rm /etc/localtime \
  && dpkg-reconfigure --frontend noninteractive tzdata

#============
# Locale
#============
ENV LC_ALL C.UTF-8

#============
# Copy bundler env to /etc/environment to load on cron
#============
RUN printenv | grep -E "^BUNDLE" >> /etc/environment

#============
# Rails
#============
RUN mkdir /myapp
WORKDIR /myapp
ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock
ADD niconico /myapp/niconico
RUN bundle install -j4 --without development test
ADD . /myapp
RUN RAILS_ENV=production bundle exec rake db:create db:migrate \
  && RAILS_ENV=production bundle exec whenever --update-crontab \
  && chmod 0600 /var/spool/cron/crontabs/root

CMD rsyslogd && /usr/sbin/cron -f
