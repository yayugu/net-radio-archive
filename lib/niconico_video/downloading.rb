module NiconicoVideo
  class Downloading
    CH_NAME = 'nicodou'

    def download(program)
      Main::prepare_working_dir(CH_NAME)
      path = filepath(program)
      begin
        %Q(youtube-dl -v -f "[vbr<599]+[abr>127]" -u#{username} -p#{password} http://www.nicovideo.jp/watch/1509345736)
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
