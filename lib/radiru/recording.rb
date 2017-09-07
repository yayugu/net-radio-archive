require 'net/http'
require 'shellwords'

module Radiru
  class Recording

    def record(job)
      unless exec_rec(job)
        return false
      end
      exec_convert(job)

      true
    end

    def exec_rec(job)
      Main::prepare_working_dir(job.ch)
      download_hls(job)
    end

    def get_streams_dom
      xml = Net::HTTP.get(URI("http://www.nhk.or.jp/radio/config/config_web.xml"))
      Nokogiri::XML(xml)
    end

    def parse_dom(dom, ch)
      dom.css('data').map do |stream|
        parse_stream(stream, ch)
      end
    end

    def parse_stream(dom, ch)
      if dom.css('area').text == 'tokyo'
        @m3u8_url = dom.css(ch + 'hls').text
      end
    end

    def download_hls(job)
      dom = get_streams_dom
      parse_dom(dom, job.ch)

      Main::sleep_until(job.start - 10.seconds)

      length = job.length_sec + 60
      file_path = Main::file_path_working(job.ch, title(job), 'm4a')
      arg = "\
        -loglevel warning \
        -y \
        -i #{Shellwords.escape(@m3u8_url)} \
        -t #{length} \
        -vcodec none -acodec copy -bsf:a aac_adtstoasc \
        #{Shellwords.escape(file_path)}"

      exit_status, output = Main::ffmpeg(arg)
      unless exit_status.success? && output.blank?
        Rails.logger.error "rec failed. job:#{job.id}, exit_status:#{exit_status}, output:#{output}"
        return false
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

    def title(job)
      date = job.start.strftime('%Y_%m_%d_%H%M')
      "#{date}_#{job.title}"
    end
  end
end
