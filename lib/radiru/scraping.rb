require 'date'
require 'net/http'

module Radiru
  class Program < Struct.new(:start_time, :end_time, :title)
  end

  class Scraping
    def get(ch)
      dom = get_programs_dom(ch)
      parse_dom(dom)
    end

    def get_programs_dom(ch)
      today = Date.today.strftime("%Y-%m-%d")
      xml = Net::HTTP.get(URI("http://cgi4.nhk.or.jp/hensei/api/sche-nr.cgi?tz=all&ch=net#{ch}&##{today}"))
      Nokogiri::XML(xml)
    end

    def parse_dom(dom)
      dom.css('item').map do |program|
        parse_program(program)
      end
    end

    def parse_program(dom)
      start_time = dom.css('starttime').text
      end_time = dom.css('endtime').text
      title = dom.css('title').text
      Program.new(
        start_time,
        end_time,
        title,
      )
    end
  end
end

