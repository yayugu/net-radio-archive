require 'net/https'
require 'shellwords'
require 'fileutils'
require 'base64'

module Radiko
  class Recording
    SWF_URL = 'http://radiko.jp/apps/js/flash/myplayer-release.swf'
    SWF_PATH = '/tmp/player.swf'
    KEY_PATH = '/tmp/radiko_key.png'
    RTMP_URL = 'rtmpe://f-radiko.smartstream.ne.jp'

    def record(job)
      unless exec_rec(job)
        return false
      end
      exec_convert(job)

      true
    end

    def exec_rec(job)
      Main::prepare_working_dir(job.ch)
      Main::retry do
        auth
      end
      rtmp(job)
    end

    def auth
      dl_swf
      extract_swf
      auth1
      auth2
    end

    def dl_swf
      unless File.exists?(SWF_PATH)
        Main::download(SWF_URL, SWF_PATH)
      end
    end

    def extract_swf
      unless File.exists?(KEY_PATH)
        command = "swfextract -b 12 #{SWF_PATH} -o #{KEY_PATH}"
        Main::shell_exec(command)
      end
    end

    def auth1
      uri = URI('https://radiko.jp/v2/api/auth1_fms')
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      https.start do |h|
        res = h.post(
          uri.path,
          '',
          {
            'pragma' => 'no-cache',
            'X-Radiko-App' => 'pc_ts',
            'X-Radiko-App-Version' => '4.0.0',
            'X-Radiko-User' => 'test-stream',
            'X-Radiko-Device' => 'pc',
          }
        )
        @auth_token = /x-radiko-authtoken=([\w-]+)/i.match(res.body)[1]
        @offset = /x-radiko-keyoffset=(\d+)/i.match(res.body)[1].to_i
        @length = /x-radiko-keylength=(\d+)/i.match(res.body)[1].to_i
      end
    end

    def partialkey
      open(KEY_PATH, 'rb:ASCII-8BIT') do |fp|
        fp.seek(@offset)
        return Base64.strict_encode64(fp.read(@length))
      end
    end

    def auth2
      uri = URI('https://radiko.jp/v2/api/auth2_fms')
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      https.start do |h|
        res = h.post(
          uri.path,
          '',
          {
            'pragma' => 'no-cache',
            'X-Radiko-App' => 'pc_ts',
            'X-Radiko-App-Version' => '4.0.0',
            'X-Radiko-User' => 'test-stream',
            'X-Radiko-Device' => 'pc',
            'X-Radiko-Authtoken' =>  @auth_token,
            'X-Radiko-Partialkey' =>  partialkey,
          }
        )
        @area_id = /^([^,]+),/.match(res.body)[1]
      end
    end

    def rtmp(job)
      Main::sleep_until(job.start - 10.seconds)

      length = job.length_sec + 60
      flv_path = Main::file_path_working(job.ch, title(job), 'flv')
      command = "\
        rtmpdump \
          -r #{Shellwords.escape(RTMP_URL)} \
          --playpath 'simul-stream.stream' \
          --app '#{job.ch}/_definst_' \
          -W #{SWF_URL} \
          -C S:'' -C S:'' -C S:'' -C S:#{@auth_token} \
          --live \
          --stop #{length} \
          -o #{Shellwords.escape(flv_path)} \
        2>&1"

      exit_status, output = Main::shell_exec(command)
      unless exit_status.success?
        Rails.logger.error "rec failed. job:#{job.id}, exit_status:#{exit_status}, output:#{output}"
        return false
      end

      true
    end

    def exec_convert(job)
      flv_path = Main::file_path_working(job.ch, title(job), 'flv')
      if Settings.force_mp4
        mp4_path = Main::file_path_working(job.ch, title(job), 'mp4')
        Main::convert_ffmpeg_to_mp4_with_blank_video(flv_path, mp4_path, job)
        dst_path = mp4_path
      else
        m4a_path = Main::file_path_working(job.ch, title(job), 'm4a')
        Main::convert_ffmpeg_to_m4a(flv_path, m4a_path, job)
        dst_path = m4a_path
      end
      Main::move_to_archive_dir(job.ch, job.start, dst_path)
    end

    def title(job)
      date = job.start.strftime('%Y_%m_%d_%H%M')
      "#{date}_#{job.title}"
    end
  end
end
