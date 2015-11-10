module Anitama
  class Downloading
    CH_NAME = 'anitama'

    def download(program)
      Main::prepare_working_dir(CH_NAME)
      path = filepath(program)
      begin
        Anitama::Scraping.new.download(program.book_id, path)
        if Settings.force_mp4 && /\.([a-zA-Z0-9]+?)$/.match(path)[1] == 'mp3'
          mp4_path = path.gsub(/\.([a-zA-Z0-9]+?)$/,'.mp4')
          Main::convert_ffmpeg_to_mp4_with_blank_video(path, mp4_path, program)
          path = mp4_path
        end
      rescue => e
        Rails.logger.error e
        return false
      end
      Main::move_to_archive_dir(CH_NAME, program.update_time, path)
      true
    end

    def filepath(program)
      date = program.update_time.strftime('%Y_%m_%d')
      title = "#{date}_#{program.title}"
      Main::file_path_working(CH_NAME, title, 'mp3')
    end
  end
end
