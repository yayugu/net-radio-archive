require 'net/http'
require 'time'
require 'pp'
require 'digest/md5'
require 'moji'

module Onsen
  class Program < Struct.new(:title, :number, :update_date, :file_url, :personality)
  end

  class Scraping
    def main
      get_program_list
    end

    def get_program_list
      dom = get_dom()
      parse_dom(dom).reject do |program|
        program == nil
      end
    end

    def parse_dom(dom)
      programs = dom.css('program')
      programs.to_a.map do |program|
        parse_program(program)
      end
    end

    def parse_program(dom)
      title = Moji.normalize_zen_han(dom.css('title').text)
      number = dom.css('program_number').text
      update_date_str = dom.css('up_date').text
      if update_date_str == ""
        return nil
      end
      update_date = Time.parse(update_date_str)

      # well known file type: mp3, mp4(movie)
      file_url = dom.css('iphone_url').text
      if file_url == ""
        return nil
      end

      personality = Moji.normalize_zen_han(dom.css('actor_tag').text)
      Program.new(title, number, update_date, file_url, personality)
    end

    def get_dom()
      url = "http://www.onsen.ag/app/programs.xml"
      code_date = Time.now.strftime("%w%d%H")
      code = Digest::MD5.hexdigest("onsen#{code_date}")
      res = Net::HTTP.post_form(
        URI.parse(url),
        'code' => code,
        'file_name' => "regular_1"
      )
      unless res.kind_of?(Net::HTTPSuccess)
        Rails.logger.error "onsen scraping error: #{url}, #{res.code}"
      end
      Nokogiri::XML.parse(res.body)
    end
  end
end
