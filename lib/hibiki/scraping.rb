require 'net/http'
require 'time'
require 'pp'

module Hibiki
  class Program < Struct.new(:access_id, :episode_id, :title, :episode_name, :cast)
  end

  class Scraping
    def main
      get_list.reject do |program|
        program.episode_id == nil
      end
    end

    def get_list
      programs = []
      parsed = nil
      page = 1
      begin
        uri = URI("https://vcms-api.hibiki-radio.jp/api/v1//programs?limit=8&page=#{page}")
        res = Net::HTTP.get(uri)
        raws = JSON.parse(res)
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
