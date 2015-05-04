module Onsen
  class Downloading
    CH_NAME = 'onsen'

    def download(program)
      uri = URI(program.file_url)
      path = filepath(program)
      Main::prepare_working_dir(CH_NAME)
      Main::download(program.file_url, path)
      Main::move_to_archive_dir(CH_NAME, program.date, path)
    end

    def filepath(program)
      url_path = URI.parse(program.file_url).path
      ext = /\.([a-zA-Z0-9]+?)$/.match(url_path)[1]
      date = program.date.strftime('%Y_%m_%d')
      title = "#{date}_#{program.title}_#{program.personality}"
      Main::file_path_working(CH_NAME, title, ext)
    end
  end
end
