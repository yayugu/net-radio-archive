require 'shellwords'
require 'fileutils'

module Hibiki
  class Downloading
    CH_NAME = 'hibiki'

    def download(program)
      unless exec_rec(program)
        return false
      end
      exec_convert(program)
    end

    def exec_rec(program)
      flv_path = Main::file_path_working(CH_NAME, title(program), 'flv')
      command = "rtmpdump -q -r #{Shellwords.escape(program.rtmp_url)} -o #{Shellwords.escape(flv_path)}"

      Main::prepare_working_dir(CH_NAME)
      exit_status, output = Main::shell_exec(command)
      unless exit_status.success?
        #Rails.logger.error "rec failed. program:#{program}, exit_status:#{exit_status}, output:#{output}"
        return false
      end

      true
    end

    def exec_convert(program)
      flv_path = Main::file_path_working(CH_NAME, title(program), 'flv')
      mp4_path = Main::file_path_working(CH_NAME, title(program), 'mp4')
      Main::convert_ffmpeg_to_mp4(flv_path, mp4_path, program)
      Main::move_to_archive_dir(CH_NAME, program.created_at, mp4_path)
    end

    def title(program)
      date = program.created_at.strftime('%Y_%m_%d')
      title = "#{date}_#{program.title}_#{program.comment}"
    end
  end
end
