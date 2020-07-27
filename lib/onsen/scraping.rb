require 'net/http'
require 'time'
require 'pp'
require 'moji'
require 'tempfile'
require 'json'

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
      number = content['title']
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
      url = "https://www.onsen.ag/"
      res = @a.get(url)
      script = res.search("script").find do |element|
        element.text.start_with?('window.__NUXT__')
      end

      ctx = Tempfile.create("script") do |f|
        f.puts "window={};#{script.text};console.log(JSON.stringify(window.__NUXT__));"
        output = eval_js(f.path)
        output.nil? ? nil : JSON.parse(output)
      end

      return [] if ctx.nil?
      programs = ctx['state']['programs']['programs']
      # mon - sun
      (1..6).map { |n| programs[n.to_s] }.flatten
    end

    def eval_js(path)
      command = "qjs #{path}"
      exit_status, output = Main::shell_exec(command)
      unless exit_status.success?
        Rails.logger.error "eval js failed. exit_status:#{exit_status}"
        return nil
      end
      output
    end
  end
end
