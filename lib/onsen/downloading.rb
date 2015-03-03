module Onsen
  class Downloading
    CH_NAME = 'onsen'

    def download(program)
      Main::prepare_dirs(CH_NAME)

      uri = URI(program.file_url)
      Main::download(program.file_url, filepath(program))

      true
    end

    def filepath(program)
      url_path = URI.parse(program.file_url).path
      ext = /\.([a-zA-Z0-9]+?)$/.match(url_path)[1]
      date = program.date.strftime('%Y_%m_%d')
      title = "#{date}_#{program.title}_#{program.personality}"
      Main::file_path_archive(CH_NAME, title, ext)
    end
  end
end
