module Onsen
  class Downloading
    CH_NAME = 'onsen'

    def download(program)
      path = filepath(program)
      Main::prepare_working_dir(CH_NAME)
      succeed = Main::download(program.file_url, path)
      unless succeed
        return false
      end
      if Settings.force_mp4 && /\.([a-zA-Z0-9]+?)$/.match(path)[1] == 'mp3'
        mp4_path = path.gsub(/\.([a-zA-Z0-9]+?)$/,'.mp4')
        Main::convert_ffmpeg_to_mp4_with_blank_video(path, mp4_path, program)
        path = mp4_path
      end
      Main::move_to_archive_dir(CH_NAME, program.date, path)
      true
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
