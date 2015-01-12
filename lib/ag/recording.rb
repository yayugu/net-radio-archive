require 'shellwords'
require 'fileutils'

module Ag
  class Recording
    AGQR_STREAM_URL = 'rtmp://fms-base2.mitene.ad.jp/agqr/aandg22'

    def record(job)
      unless exec_rec(job)
        return false
      end
      exec_convert(job)
    end

    def exec_rec(job)
      filename = job.title
        .gsub(/\s/, '_')
        .gsub(/\//, '_')
      length = job.length_sec + 120
      flv_path = filepath(job, 'flv')
      command = "rtmpdump -q -r #{Shellwords.escape(AGQR_STREAM_URL)} --live --stop #{length} -o #{Shellwords.escape(flv_path)}"

      FileUtils.mkdir_p(ag_dir)
      exit_status, output = Main::shell_exec(command)
      unless exit_status.success?
        Rails.logger.error "rec failed. job:#{job}, exit_status:#{exit_status}, output:#{output}"
        return false
      end

      true
    end

    def exec_convert(job)
      flv_path = filepath(job, 'flv')
      mp4_path = filepath(job, 'mp4')
      command = "avconv -loglevel error -y -i #{Shellwords.escape(flv_path)} -vcodec copy -acodec copy #{Shellwords.escape(mp4_path)}"
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
      "#{ag_dir}/#{date}_#{title_safe}.#{ext}"
    end

    def ag_dir
      "#{ENV['NET_RADIO_ARCHIVE_DIR']}/ag"
    end
  end
end
