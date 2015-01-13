require 'net/https'
require 'shellwords'
require 'fileutils'
require 'base64'

module Radiko
  class Recording
    SWF_URL = 'http://radiko.jp/player/swf/player_4.1.0.00.swf'
    SWF_PATH = '/tmp/player.swf'
    KEY_PATH = '/tmp/radiko_key.png'
    RTMP_URL = 'rtmpe://f-radiko.smartstream.ne.jp'

    def record(job)
      unless exec_rec(job)
        return false
      end
      exec_convert(job)
    end

    def exec_rec(job)
      auth
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
        command = "swfextract -b 14 #{SWF_PATH} -o #{KEY_PATH}"
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
            'X-Radiko-App' => 'pc_1',
            'X-Radiko-App-Version' => '2.0.1',
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
            'X-Radiko-App' => 'pc_1',
            'X-Radiko-App-Version' => '2.0.1',
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
      length = job.length_sec + 120
      flv_path = filepath(job, 'flv')
      command = "\
        rtmpdump -q \
        -r #{Shellwords.escape(RTMP_URL)} \
        --playpath 'simul-stream.stream' \
        --app '#{job.ch}/_definst_' \
        -W #{SWF_URL} \
        -C S:'' -C S:'' -C S:'' -C S:#{@auth_token} \
        --live \
        --stop #{length} \
        -o #{Shellwords.escape(flv_path)}"

      FileUtils.mkdir_p(dir(job.ch))
      exit_status, output = Main::shell_exec(command)
      unless exit_status.success?
        Rails.logger.error "rec failed. job:#{job}, exit_status:#{exit_status}, output:#{output}"
        return false
      end

      true
    end

    def exec_convert(job)
      flv_path = filepath(job, 'flv')
      aac_path = filepath(job, 'aac')
      command = "avconv -loglevel error -y -i #{Shellwords.escape(flv_path)} -acodec copy #{Shellwords.escape(aac_path)}"
      exit_status, output = Main::shell_exec(command)
      unless exit_status.success?
        Rails.logger.error "convert failed. job:#{job}, exit_status:#{exit_status}, output:#{output}"
        return false
      end

      true
    end

    def filepath(job, ext)
      date = job.start.strftime('%Y_%m_%d_%H%M')
      title_safe = job.title
        .gsub(/\s/, '_')
        .gsub(/\//, '_')
      "#{dir(job.ch)}/#{date}_#{title_safe}.#{ext}"
    end

    def dir(ch)
      "#{ENV['NET_RADIO_ARCHIVE_DIR']}/#{ch}"
    end
  end
end
