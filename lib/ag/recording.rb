require 'shellwords'
require 'fileutils'

module Ag
  class Recording
    AGQR_STREAM_URL = 'rtmp://fms-base2.mitene.ad.jp/agqr/aandg22'
    CH_NAME = 'ag'

    def record(job)
      unless exec_rec(job)
        return false
      end
      exec_convert(job)

      true
    end

    def exec_rec(job)
      Main::prepare_working_dir(CH_NAME)
      Main::sleep_until(job.start - 10.seconds)

      length = job.length_sec + 60
      flv_path = Main::file_path_working(CH_NAME, title(job), 'flv')
      command = "rtmpdump -q -r #{Shellwords.escape(AGQR_STREAM_URL)} --live --stop #{length} -o #{Shellwords.escape(flv_path)}"
      exit_status, output = Main::shell_exec(command)
      unless exit_status.success?
        Rails.logger.error "rec failed. job:#{job}, exit_status:#{exit_status}, output:#{output}"
        return false
      end

      true
    end

    def exec_convert(job)
      flv_path = Main::file_path_working(CH_NAME, title(job), 'flv')
      mp4_path = Main::file_path_working(CH_NAME, title(job), 'mp4')
      Main::convert_ffmpeg_to_mp4(flv_path, mp4_path, job)
      Main::move_to_archive_dir(CH_NAME, job.start, mp4_path)
    end

    def title(job)
      date = job.start.strftime('%Y_%m_%d_%H%M')
      "#{date}_#{job.title}"
    end
  end
end
