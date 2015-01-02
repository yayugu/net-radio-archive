require 'net/http'
require 'time'
require 'pp'
require 'digest/md5'
require 'moji'

module Hibiki
  class Program < Struct.new(:title, :comment, :rtmp_url)
  end
  class ProgramBase < Struct.new(:title, :comment, :short_name, :channel_id)
  end

  class Scraping
    def main
      (0..6).inject([]) do |program_list, wday|
        sleep(1)
        program_list += get_wday(wday)
      end
    end

    def get_wday(wday)
      get_wday_base(wday).map do |base|
        sleep(1)
        add_program_detail(base)
      end.compact # remove nil
    end

    def add_program_detail(base)
      rtmp_url = get_rtmp_url(base)
      unless rtmp_url
        return nil
      end
      Program.new(
        base.title,
        base.comment,
        rtmp_url
      )
    end

    def get_wday_base(wday)
      dom_programs = get_wday_doms(wday)
      parse_programs(dom_programs)
    end

    def get_wday_doms(wday)
      uri = URI.parse("http://hibiki-radio.jp/get_program/#{wday}")
      html = Net::HTTP.get(uri)
      dom = Nokogiri::HTML.parse(html)
      dom.css('a')
    end

    def parse_programs(dom_programs)
      dom_programs.map do |dom_program|
        parse_program dom_program
      end
    end

    def parse_program(dom)
      title = parse_title(dom)
      comment = Moji.normalize_zen_han(dom.css('.hbkProgramComment').text)
      short_name, channel_id = parse_onclick(dom.attribute('onclick').value)
      ProgramBase.new(
        title,
        comment,
        short_name,
        channel_id
      )
    end

    def parse_title(dom)
      t = dom.css('.hbkProgramButton').text
      if t.blank?
        t = dom.css('.hbkProgramButtonNew').text
      end

      Moji.normalize_zen_han(t.strip.gsub(/(\r\n|\r|\n)/, ' '))
    end

    def parse_onclick(onclick_text)
      m = /AttachVideo\('(.+?)','(.+?)','.+?','.+?'\)/.match(onclick_text)
      [m[1], m[2]]
    end

    def get_rtmp_url(base)
      dom = get_channel_dom(base)
      unless dom
        return nil
      end
      parse_channel_dom(dom)
    end

    def parse_channel_dom(dom)
      protocol = dom.css('protocol').text
      domain = dom.css('domain').text
      dir = dom.css('dir').text
      flv = dom.css('flv').text
      if protocol.blank? || domain.blank? || dir.blank? || flv.blank?
        return nil
      end
      m = /^.+?\:(.+)$/.match(flv)
      filename_query = m[1]
      "#{protocol}://#{domain}/#{dir}/#{filename_query}"
    end

    def get_channel_dom(base)
      uri = URI.parse("http://image.hibiki-radio.jp/uploads/data/channel/#{base.short_name}/#{base.channel_id}.xml")

      res = Net::HTTP.get_response(uri)
      unless res.is_a?(Net::HTTPSuccess)
        return nil
      end

      # the response is XML but not valid.
      # parse as HTML to expect parsing more fuzzy.
      Nokogiri::HTML.parse(res.body)
    end

  end
end
