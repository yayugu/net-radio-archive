require 'net/http'
require 'time'
require 'pp'
require 'moji'

module Onsen
  class Program < Struct.new(:title, :number, :update_date, :file_url, :personality)
  end

  class Scraping
    def initialize
      @a = Mechanize.new
      @a.user_agent_alias = 'Windows Chrome'
    end

    def main
      get_program_list
    end

    def get_program_list
      programs = get_programs()
      parse_programs(programs).reject do |program|
        program == nil
      end
    end

    def parse_programs(programs)
      programs.map do |program|
        parse_program(program)
      end
    end

    def parse_program(program)
      content = program['contents'].find do |content|
        content['latest'] && !content['premium']
      end
      return nil if content.nil?

      title = Moji.normalize_zen_han(program['title'])
      number = Moji.normalize_zen_han(content['title'])
      update_date_str = content['delivery_date']
      if update_date_str == ""
        return nil
      end
      update_date = Time.parse(update_date_str)

      file_url = content['streaming_url']
      if file_url == ""
        return nil
      end

      personality = program['performers'].map do |performer|
        Moji.normalize_zen_han(performer['name'])
      end.join(',')
      Program.new(title, number, update_date, file_url, personality)
    end

    def get_programs()
      url = "https://www.onsen.ag/web_api/programs"
      res = @a.get(url)
      JSON.parse(res.body)
    end
  end
end
