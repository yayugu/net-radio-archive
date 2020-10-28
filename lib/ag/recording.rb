require 'shellwords'
require 'fileutils'

module Ag
  class Recording
    AGQR_STREAM_URL = 'https://fms2.uniqueradio.jp/agqr10/aandg1.m3u8'
    CH_NAME = 'ag'

    def record(job)
      exec_rec(job)
    end

    def exec_rec(job)
      Main::prepare_working_dir(CH_NAME)
      Main::sleep_until(job.start - 10.seconds)

      length = job.length_sec + 90
      file_path = Main::file_path_working(CH_NAME, title(job), 'mp4')
      arg = "\
        -loglevel error \
        -y \
        -allowed_extensions ALL \
        -protocol_whitelist file,crypto,http,https,tcp,tls \
        -i #{AGQR_STREAM_URL} \
        -t #{length} \
        -vcodec copy -acodec copy -bsf:a aac_adtstoasc \
        #{Shellwords.escape(file_path)}"
      exit_status, output = Main::ffmpeg(arg)
      unless exit_status.success?
        Rails.logger.error "rec failed. job:#{job}, exit_status:#{exit_status}, output:#{output}"
        return false
      end
      if output.present?
        Rails.logger.warn "ag ffmpeg command:#{arg} output:#{output}"
      end

      Main::move_to_archive_dir(CH_NAME, job.start, file_path)
      true
    end

    def title(job)
      date = job.start.strftime('%Y_%m_%d_%H%M')
      "#{date}_#{job.title}"
    end
  end
end
