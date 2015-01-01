require 'net/http'
require 'time'
require 'pp'
require 'digest/md5'

module Onsen
  class Program < Struct.new(:title, :number, :update_date, :file_url, :personality)
  end

  class Scraping
    def main
      get_program_list
    end

    def get_program_list
      (0..6).inject([]) do |progam_list, wday|
        sleep(1)
        dom = get_dom(wday)
        progam_list += parse_dom_wday(dom, wday)
      end
    end

    def parse_dom_wday(dom, wday)
      programs = dom.css('program')
      programs.to_a.map do |program|
        parse_program(program, wday)
      end
    end

    def parse_program(dom, wday)
      title = dom.css('title').text
      number = dom.css('number').text
      update_date = parse_date(dom.css('update').text)

      # well known file type: mp3, mp4(movie)
      file_url = dom.css('fileUrlIphone').text

      personality = dom.css('personality').text
      Program.new(title, number, update_date, file_url, personality)
    end

    def parse_date(month_day)
      month, day = parse_month_day(month_day)
      unless month && day
        return nil
      end
      year = now_smaller_than_target?(month, day) \
        ? Time.now.year - 1
        : Time.now.year
      Time.new(year, month, day)
    end

    def parse_month_day(month_day)
      m = /(\d+)\/(\d+)/.match(month_day)
      unless m
        return nil
      end
      [m[1].to_i, m[2].to_i]
    end

    def now_smaller_than_target?(target_month, target_day)
      now = Time.now.strftime("%02m%02d").to_i
      target = sprintf("%02d%02d", target_month, target_day).to_i
      now < target
    end

    def get_dom(wday)
      unix_m = Time.now.strftime("%s%L")
      url = "http://onsen.ag/getXML.php?#{unix_m}"
      code_date = Time.now.strftime("%w%d%H")
      code = Digest::MD5.hexdigest("onsen#{code_date}")
      res = Net::HTTP.post_form(
        URI.parse(url),
        'code' => code,
        'file_name' => "regular_#{wday}"
      )
      dom = Nokogiri::XML.parse(res.body)
    end
  end
end
