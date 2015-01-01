require 'net/http'

module Onsen
  class Downloading
    def download(program)
      uri = URI(program.file_url)

      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri.request_uri

        http.request request do |response|
          open filepath(program), 'wb' do |io|
            response.read_body do |chunk|
              io.write chunk
            end
          end
        end
      end

      true
    end

    def filepath(program)
      url_path = URI.parse(program.file_url).path
      ext = /\.([a-zA-Z0-9]+?)$/.match(url_path)[1]
      date = program.date.strftime('%Y_%m_%d')
      title_safe = "#{program.title}_#{program.personality}"
        .gsub(/\s/, '_')
        .gsub(/\//, '_')
      "#{ENV['NET_RADIO_ARCHIVE_DIR']}/onsen/#{date}_#{title_safe}_\##{program.number}.#{ext}"
    end
  end
end
