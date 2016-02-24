require 'net/http'
require 'shellwords'

module Radiru
  class Recording
    SWF_URL = 'http://www3.nhk.or.jp/netradio/files/swf/rtmpe.swf'

    def record(job)
      unless exec_rec(job)
        return false
      end
      exec_convert(job)

      true
    end

    def exec_rec(job)
      Main::prepare_working_dir(job.ch)
      rtmp(job)
    end

    def get_streams_dom
      xml = Net::HTTP.get(URI("http://www3.nhk.or.jp/netradio/app/config_pc.xml"))
      Nokogiri::XML(xml)
    end

    def parse_dom(dom, ch)
      dom.css('data').map do |stream|
        parse_stream(stream, ch)
      end
    end

    def parse_stream(dom, ch)
      if dom.css('area').text == 'tokyo'
        urlArray = dom.css(ch).text.split("/live/")
        @url = urlArray[0]
        @path = urlArray[1]
      end
    end

    def rtmp(job)
      dom = get_streams_dom
      parse_dom(dom, job.ch)

      Main::sleep_until(job.start - 10.seconds)

      length = job.length_sec + 60
      flv_path = Main::file_path_working(job.ch, title(job), 'flv')
      command = "\
        rtmpdump \
          -r #{Shellwords.escape(@url)} \
          --playpath #{@path} \
          --app 'live' \
          -W #{SWF_URL} \
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
