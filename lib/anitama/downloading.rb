module Anitama
  class Downloading
    CH_NAME = 'anitama'

    def download(program)
      Main::prepare_working_dir(CH_NAME)
      path = filepath(program)
      begin
        Anitama::Scraping.new.download(program.book_id, path)
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
