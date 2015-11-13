require 'net/http'
require 'time'
require 'pp'

module Hibiki
  class Program < Struct.new(:access_id, :episode_id, :title, :episode_name, :cast)
  end

  class Scraping
    def initialize
      @a = Mechanize.new
      @a.user_agent_alias = 'Windows Chrome'
    end

    def main
      get_list.reject do |program|
        program.episode_id == nil
      end
    end

    def get_list
      programs = []
      page = 1
      begin
        res = @a.get(
          "https://vcms-api.hibiki-radio.jp/api/v1//programs?limit=8&page=#{page}",
          [],
          "http://hibiki-radio.jp/",
          'X-Requested-With' => 'XMLHttpRequest',
          'Origin' => 'http://hibiki-radio.jp'
        )
        raws = JSON.parse(res.body)
        programs += raws.map{|raw| parse_program(raw) }
        sleep 1
        page += 1
      end while raws.size == 8
      programs
    end

    def parse_program(raw)
      Program.new(
        raw['access_id'],
        raw['latest_episode_id'],
        raw['name'],
        raw['latest_episode_name'],
        raw['cast'],
      )
    end
  end
end
