require 'net/http'
require 'fileutils'

module Onsen
  class Downloading
    def download(program)
      uri = URI(program.file_url)

      FileUtils.mkdir_p(onsen_dir)
      Main::download(program.file_url, filepath(program))

      true
    end

    def filepath(program)
      url_path = URI.parse(program.file_url).path
      ext = /\.([a-zA-Z0-9]+?)$/.match(url_path)[1]
      date = program.date.strftime('%Y_%m_%d')
      title_safe = "#{program.title}_#{program.personality}"
        .gsub(/\s/, '_')
        .gsub(/\//, '_')
      "#{onsen_dir}/#{date}_#{title_safe}_\##{program.number}.#{ext}"
    end

    def onsen_dir
      "#{ENV['NET_RADIO_ARCHIVE_DIR']}/onsen"
    end
  end
end
