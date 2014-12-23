require 'net/http'
require 'time'
require 'chronic'
require 'pp'

module Ag
  class Program < Struct.new(:start_time, :minutes, :title)
  end

  class ProgramTime < Struct.new(:wday, :time)
    SAME_DAY_LINE_HOUR = 4

    # convert human friendly time to computer friendly time
    def self.parse(wday, time_str)
      time = Time.parse(time_str)
      if time.hour < SAME_DAY_LINE_HOUR
        wday = (wday + 1) % 7
      end
      self.new(wday, time)
    end

    def next_on_air
      Chronic.parse(
        "#{wday_to_s(self[:wday])} #{self[:time].strftime("%H:%M")}",
        context: :future,
        ambiguous_time_range: :none,
        hours24: true,
        guess: :begin
      )
    end

    def wday_to_s(wday)
      %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)[wday]
    end
  end

  class Scraping
    def main
      programs = scraping_page('http://www.agqr.jp/timetable/digital-mf.php') +
        scraping_page('http://www.agqr.jp/timetable/digital-ss.php')
      programs = validate_programs(programs)
      programs
    end

    def validate_programs(programs)
      programs.delete_if do |program|
        program.title == '放送休止'
      end
    end

    def scraping_page(url)
      html = Net::HTTP.get(URI.parse(url))
      dom = Nokogiri::HTML.parse(html)
      domsub = dom.css('#timetable2 #timeline')
      domsub.inject([]) do |programs, week|
        programs + parse_week_dom(week)
      end
    end

    def parse_week_dom(dom)
      wday = determine_wday(dom.css('th')[0].text)
      dom.css('td').map do |program|
        parse_program(program, wday)
      end
    end

    def parse_program(dom, wday)
      start_time = ProgramTime.parse(wday, dom.css('strong')[0].text)
      m = determine_minutes(dom['class'])
      title = parse_program_title(dom)
      Program.new(start_time, m, title)
    end

    def parse_program_title(dom)
      without_time_info = dom.children.dup
      without_time_info.shift
      without_time_info.select do |node|
        !node.text.gsub(/\s/, '').empty?
      end.map do |node|
        Moji.normalize_zen_han(node.text).strip
      end.join(' ')
    end

    def determine_wday(week_str)
      case week_str
      when /日曜/
        0
      when /月曜/
        1
      when /火曜/
        2
      when /水曜/
        3
      when /木曜/
        4
      when /金曜/
        5
      when /土曜/
        6
      end
    end

    # see http://agqr.jp/css/content.css
    def determine_minutes(length_css_class)
      case length_css_class
      when 't05'
        5
      when 't10'
        10
      when 't15'
        15
      when 't15-2'
        15
      when 't30'
        30
      when 't45'
        45
      when 't60'
        60
      when 't90'
        90
      when 't120'
        120
      when 't180'
        180
      end
    end
  end
end
