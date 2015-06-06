module Anitama
  class Downloading
    CH_NAME = 'anitama'

    def download(program)
      Main::prepare_woking_dir(CH_NAME)
      path = filepath(program)
      Anitama::Scraping.new.download(program.book_id, path)
      Main::move_to_archive_dir(CH_NAME, program.update_time, path)
    end

    def filepath(program)
      date = program.update_time.strftime('%Y_%m_%d')
      title = "#{date}_#{program.title}"
      Main::file_path_working(CH_NAME, title, 'mp3')
    end
  end
end
