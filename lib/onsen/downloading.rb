module Onsen
  class Downloading
    CH_NAME = 'onsen'

    def download(program)
      path = filepath(program)
      Main::prepare_working_dir(CH_NAME)
      arg = "\
        -loglevel error \
        -y \
        -headers 'Referer: https://www.onsen.ag/' \
        -i #{Shellwords.escape(program.file_url)} \
        -vcodec libx264 -acodec copy -bsf:a aac_adtstoasc \
        #{Shellwords.escape(path)}"

      exit_status, output = Main::ffmpeg(arg)
      unless exit_status.success? && output.blank?
        Rails.logger.error "rec failed. onsen program:#{program.id}, exit_status:#{exit_status}, output:#{output}"
        return false
      end
      Main::move_to_archive_dir(CH_NAME, program.date, path)
      true
    end

    def filepath(program)
      date = program.date.strftime('%Y_%m_%d')
      title = "#{date}_#{program.title}_#{program.number}_#{program.personality}"
      Main::file_path_working(CH_NAME, title, 'mp4')
    end
  end
end
