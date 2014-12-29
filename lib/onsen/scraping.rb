require 'net/http'
require 'time'
require 'pp'
require 'digest/md5'

module Onsen
  class Scraping

    def main
      tfmt = Time.now.strftime("%Y%M")

      unix_m = Time.now.strftime("%s%L")
      url = "http://onsen.ag/getXML.php?#{unix_m}"
      code_date = Time.now.strftime("%w%d%H")
      code = Digest::MD5.hexdigest("onsen#{code_date}")
      res = Net::HTTP.post_form(
        URI.parse(url),
        'code' => code,
        'file_name' => "regular_1"
      )
      dom = Nokogiri::XML.parse(res.body)
      puts res.body
    end
  end
end
