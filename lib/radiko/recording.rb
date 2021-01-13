require 'net/https'
require 'shellwords'
require 'fileutils'
require 'base64'

module Radiko
  class Recording
    AUTH_KEY = 'bcd151073c03b352e1ef2fd66c32209da9ca0afa'
    WORK_DIR_NAME = 'radiko'

    def initialize
      @cookie = ''
    end

    def record(job)
      unless exec_rec(job)
        return false
      end
      exec_convert(job)

      true
    end

    def exec_rec(job)
      begin
        Main::prepare_working_dir(WORK_DIR_NAME)
        Main::prepare_working_dir(job.ch)
        Main::retry do
          auth(job)
        end
				m3u8_chunk(job)
        download_hls(job)
      ensure
        logout
      end
    end

    def auth(job)
      login(job)
      auth1
      auth2
    end

    def login(job)
      if !Settings.radiko_premium ||
          !Settings.radiko_premium.mail ||
          !Settings.radiko_premium.password ||
          !Settings.radiko_premium.channels.include?(job.ch)
        return
      end
      uri = URI('https://radiko.jp/ap/member/login/login')
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      https.start do |h|
        req = Net::HTTP::Post.new(uri.path)
        req.set_form_data(
            'mail' => Settings.radiko_premium.mail,
            'pass' => Settings.radiko_premium.password,
        )
        res = h.request(req)
        @cookie = res.response['set-cookie']
      end
    end

    def auth1
      uri = 'https://radiko.jp/v2/api/auth1'
      res = HTTParty.get(uri, {
        headers: {
					'pragma' => 'no-cache',
					'X-Radiko-App' => 'pc_html5',
					'X-Radiko-App-Version' => '0.0.1',
					'X-Radiko-User' => 'test-stream',
					'X-Radiko-Device' => 'pc',
					'Cookie' => @cookie,
        }
      })
			@auth_token = res.headers['x-radiko-authtoken']
			@offset = res.headers['x-radiko-keyoffset'].to_i
			@length = res.headers['x-radiko-keylength'].to_i
    end

    def partialkey
      return Base64.strict_encode64(AUTH_KEY[@offset, @length])
    end

    def auth2
      uri = 'https://radiko.jp/v2/api/auth2'
      res = HTTParty.get(uri, {
        headers: {
					'pragma' => 'no-cache',
					'X-Radiko-User' => 'test-stream',
					'X-Radiko-Device' => 'pc',
					'X-Radiko-AuthToken' => @auth_token,
					'X-Radiko-PartialKey' => partialkey,
					'Cookie' => @cookie,
        }
      })
			p res
			p res.body
    end

    def m3u8_chunk(job)
      uri = "http://c-radiko.smartstream.ne.jp/#{job.ch}/_definst_/simul-stream.stream/playlist.m3u8"
      uri_alt = "http://f-radiko.smartstream.ne.jp/#{job.ch}/_definst_/simul-stream.stream/playlist.m3u8"
      begin
        p uri
        res = HTTParty.get(uri, {
          headers: {
            'X-Radiko-Authtoken' => @auth_token
          }
        })
        p res
        @m3u8_url = /^https?:\/\/.+m3u8$/i.match(res.body)[0]
      rescue => e
        if uri != uri_alt
          uri = uri_alt
          retry
        else
          raise e
        end
      end
    end

    def download_hls(job)
      Main::sleep_until(job.start - 10.seconds)

      length = job.length_sec + 90
      file_path = Main::file_path_working(job.ch, title(job), 'm4a')
      arg = "\
        -loglevel warning \
        -headers 'X-Radiko-AuthToken: #{@auth_token}\r\n' \
        -y \
        -i #{Shellwords.escape(@m3u8_url)} \
        -t #{length} \
        -vcodec none -acodec copy -bsf:a aac_adtstoasc \
        #{Shellwords.escape(file_path)}"

      exit_status, output = Main::ffmpeg(arg)
      unless exit_status.success?
        Rails.logger.error "rec failed. job:#{job.id}, exit_status:#{exit_status}, output:#{output}"
        return false
      end
      if output.present?
        Rails.logger.warn "radiko ffmpeg command:#{arg} output:#{output}"
      end

      true
    end

    def exec_convert(job)
      m4a_path = Main::file_path_working(job.ch, title(job), 'm4a')
      if Settings.force_mp4
        mp4_path = Main::file_path_working(job.ch, title(job), 'mp4')
        Main::convert_ffmpeg_to_mp4_with_blank_video(m4a_path, mp4_path, job)
        dst_path = mp4_path
      else
        dst_path = m4a_path
      end
      Main::move_to_archive_dir(job.ch, job.start, dst_path)
    end

    def logout
      if @cookie.empty?
        return
      end
      uri = URI('https://radiko.jp/ap/member/webapi/member/logout')
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      https.start do |h|
        res = h.get(
            uri.path,
            {
                'pragma' => 'no-cache',
                'Accept' => 'application/json, text/javascript, */*; q=0.01',
                'X-Radiko-App-Version' => 'application/json, text/javascript, */*; q=0.01',
                'X-Requested-With' => 'XMLHttpRequest',
                'Cookie' => @cookie,
            }
        )
      end
    end

    def title(job)
      date = job.start.strftime('%Y_%m_%d_%H%M')
      "#{date}_#{job.title}"
    end
  end
end
