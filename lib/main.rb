module Main
  def self.download(url, filename)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      http.request(request) do |response|
        open(filename, 'wb') do |io|
          response.read_body do |chunk|
            io.write chunk
          end
        end
      end
    end
  end

  def self.shell_exec(command)
    output = `#{command}`
    exit_status = $?
    [exit_status, output]
  end
end
