require 'net/http'
require 'time'
require 'chronic'
require 'pp'
require 'moji'

module Ag
  class Program < Struct.new(:start_time, :minutes, :title)
  end

  class ProgramTime < Struct.new(:wday, :time)
    SAME_DAY_LINE_HOUR = 5

    # convert human friendly time to computer friendly time
    def self.parse(wday, time_str)
      m = time_str.match(/(\d+):(\d+)/)
      hour = m[1].to_i
      min = m[2].to_i
      over_24_oclock = false
      if hour >= 24 # 25:00 とかの表記用
        over_24_oclock = true
        hour -= 24
        wday = (wday + 1) % 7
      end
      time_str_fixed = sprintf("%02d:%02d", hour, min)
      time = Time.parse(time_str_fixed)
      if !over_24_oclock && time.hour < SAME_DAY_LINE_HOUR # 01:00 とかの表記用。現在は使われていないが一応
        wday = (wday + 1) % 7
      end
      self.new(wday, time)
    end

    def next_on_air
      time = chronic(wday_for_chronic_include_today(self[:wday]))
      if time > Time.now
        return time
      else
        chronic(wday_to_s(self[:wday]))
      end
    end

    def chronic(day_str)
      Chronic.parse(
        "#{day_str} #{self[:time].strftime("%H:%M")}",
        context: :future,
        ambiguous_time_range: :none,
        hours24: true,
        guess: :begin
      )
    end

    def wday_for_chronic_include_today(wday)
      if Time.now.wday == wday
        return 'today'
      end
      wday_to_s(wday)
    end

    def wday_to_s(wday)
      %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)[wday]
    end
  end

  class Scraping
    def main
      programs = scraping_page
      programs = validate_programs(programs)
      programs
    end

    def validate_programs(programs)
      if programs.size < 20
        puts "Error: Number of programs is too few!"
        exit
      end
      programs.delete_if do |program|
        program.title == '番組休止中' || program.title == '放送休止'
      end
    end

    def scraping_page
      target_date = Date.today.next_day
      res = HTTParty.get("https://www.joqr.co.jp/qr/agdailyprogram/?date=#{target_date.strftime('%Y%m%d')}")
      dom = Nokogiri::HTML.parse(res.body)
      program_items = dom.css('.dailyProgram-itemBox')
      parse_program(program_items, target_date.wday)
    end

    def parse_program(program_items, wday)
      program_items.map do |item|
        start_time = parse_start_time(item, wday)
        minutes = parse_minutes(item, wday)
        title = parse_title(item)
        Program.new(start_time, minutes, title);
      end
    end

    def parse_minutes(item, wday)
      header_time = item.css('.dailyProgram-itemHeaderTime').text.strip
      start_time, end_time = parse_header_time(header_time)
      s = ProgramTime.parse(wday, start_time).next_on_air
      e = ProgramTime.parse(wday, end_time).next_on_air
      (e - s).floor / 60
    end

    def parse_header_time(header_time)
      header_time.scan(/([0-9]+:[0-9]+) .+ ([0-9]+:[0-9]+)/).first
    end

    def parse_start_time(item, wday)
      header_time = item.css('.dailyProgram-itemHeaderTime').text.strip
      start_time, _ = parse_header_time(header_time)
      ProgramTime.parse(wday, start_time)
    end

    def parse_title(item)
      title = item.css('.dailyProgram-itemTitle').text.strip
      personality = item
        .css('.dailyProgram-itemPersonality')
        .text
        .strip
        .gsub(' ', '')
        .gsub(',', '_')
      title += "_#{personality}" unless personality.empty?
      Moji.normalize_zen_han(title)
    end
  end
end
