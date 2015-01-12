require 'net/http'
require 'time'
require 'chronic'
require 'pp'
require 'moji'

module Radiko
  class Program < Struct.new(:start_time, :end_time, :title, :performers)
  end

  class Scraping
    def get(ch)
      dom = get_programs_dom(ch)
      programs = parse_dom(dom)
      validate_programs(programs)
    end

    def get_programs_dom(ch)
      xml = Net::HTTP.get(URI("http://radiko.jp/v2/api/program/station/weekly?station_id=#{ch}"))
      Nokogiri::XML(xml)
    end

    def parse_dom(dom)
      dom.css('prog').map do |program|
        parse_program(program)
      end
    end

    def validate_programs(programs)
      programs.delete_if do |program|
        program.title =~ /放送休止|番組休止/
      end
    end

    def parse_program(dom)
      start_time = parse_time(dom.attribute('ft').value)
      end_time = parse_time(dom.attribute('to').value)
      title = dom.css('title').text
      performers = dom.css('pfm').text
      Program.new(
        start_time,
        end_time,
        title,
        performers
      )
    end

    def parse_time(text)
      Time.strptime(text, '%Y%m%d%H%M%S')
    end
  end
end

