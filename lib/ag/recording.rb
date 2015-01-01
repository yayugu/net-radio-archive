require 'shellwords'

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
      exit_status, output = shell_exec(command)
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
      exit_status, output = shell_exec(command)
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
      "#{ENV['NET_RADIO_ARCHIVE_DIR']}/#{date}_#{title_safe}.#{ext}"
    end

    def shell_exec(command)
      output = `#{command}`
      exit_status = $?
      [exit_status, output]
    end
  end
end
