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
        program.title == '放送休止'
      end
    end


    def scraping_page
      res = HTTParty.get('http://www.agqr.jp/timetable/streaming.html')
      dom = Nokogiri::HTML.parse(res.body)
      tbody = dom.css('.timetb-ag tbody') # may be 30minutes belt
      td_list_list = parse_broken_table(tbody)
      two_dim_array = table_to_two_dim_array(td_list_list)
      day_time_array = join_box_program(transpose(two_dim_array))
      day_time_array.each_with_index.inject([]) do |programs, (programs_day, index)|
        programs + parse_day(programs_day, index)
      end
    end

    def parse_broken_table(tbody)
      # time table HTML is broken!!!!!! some row aren't opened by <tr>.
      td_list_list = []
      td_list_tmp = []
      tbody.children.each do |tag|
        if tag.name == 'td'
          td_list_tmp.push tag
        elsif tag.name == 'tr' || tag.name == 'th'
          unless td_list_tmp.empty?
            td_list_list.push td_list_tmp
            td_list_tmp = []
          end
          if tag.name == 'tr'
            td_list_list.push tag.css('td')
          end
        end
      end
      unless td_list_tmp.empty?
        td_list_list.push td_list_tmp
      end
      td_list_list
    end

    def parse_day(programs_day, index)
      wday = (index + 1) % 7 # monday start
      programs_day.map do |td|
        parse_td_dom(td, wday)
      end
    end

    def table_to_two_dim_array(td_list_list)
      aa = []
      span = {}
      td_list_list.each_with_index do |td_list, row_n|
        a = []
        col_n = 0
        td_list.each do |td|
          while span[[row_n, col_n]]
            a.push(nil)
            col_n += 1
          end
          a.push(td)
          cspan = 1
          if td['colspan'] =~ /(\d+)/
            cspan = $1.to_i
          end
          rspan = 1
          if td['rowspan'] =~ /(\d+)/
            rspan = $1.to_i
          end
          (row_n...(row_n + rspan)).each do |r|
            (col_n...(col_n + cspan)).each do |c|
              span[[r, c]] = true
            end
          end
          col_n += 1
        end
        aa.push(a)
      end
      aa
    end

    def transpose(two_dim_array)
      max_size = two_dim_array.max_by{|i| i.size }.size
      filled = two_dim_array.map{|i| i.fill(nil, i.size...max_size) }
      filled.transpose
    end

    def join_box_program(day_time_array)
      day_time_array.map do |day|
        day.inject([]) do |programs, td|
          unless td
            next programs
          end
          time = td.css('.time')[0].text
          if time.include?('頃')
            programs.last['rowspan'] = programs.last['rowspan'].to_i + td['rowspan'].to_i
            next programs
          end
          programs << td
        end
      end
    end

    def parse_td_dom(td, wday)
      start_time = parse_start_time(td, wday)
      minutes = parse_minutes(td)
      title = parse_title(td)
      Program.new(start_time, minutes, title)
    end

    def parse_minutes(td)
      rowspan = td.attribute('rowspan')
      if !rowspan || rowspan.value.blank?
        30
      else
        td.attribute('rowspan').value.to_i
      end
    end

    def parse_start_time(td, wday)
      ProgramTime.parse(wday, td.css('.time')[0].text)
    end

    def parse_title(td)
      [td.css('.title-p')[0].text, td.css('.rp')[0].text].select do |text|
        !text.gsub(/\s/, '').empty?
      end.map do |text|
        Moji.normalize_zen_han(text).strip
      end.join(' ')
    end
  end
end
