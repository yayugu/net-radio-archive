require 'date'
require 'net/https'
require 'json'

module Radiru
  class Program < Struct.new(:start_time, :end_time, :title)
  end

  class Scraping
    def get(ch)
      id = get_id(ch)
      json = get_programs_json(id)
      parse(id, json)
    end

    def get_id(ch)
      case ch
      when 'r1'
        'n1'
      when 'r2'
        'n2'
      when 'fm'
        'n3'
      end
    end

    def get_programs_json(id)
      today = Date.today.strftime("%Y-%m-%d")
      res = Net::HTTP.get(URI("https://api.nhk.or.jp/r2/pg/list/4/130/#{id}/#{today}.json"))
      JSON.parse(res);
    end

    def parse(id, json)
      json['list'][id].map do |program|
        parse_program(program)
      end
    end

    def parse_program(program)
      Program.new(
        program['start_time'],
        program['end_time'],
        program['title'],
      )
    end
  end
end

