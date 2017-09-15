# coding: utf-8
module Agonp
  class Program < Struct.new(:title, :personality, :episode_id, :price)
  end

  class Scraping
    def initialize
      @a = Mechanize.new
      @a.user_agent_alias = 'Windows Chrome'
    end

    def main
      filter_list(get_list)
    end

    def get_list
      programs = []
      page = 1
      2.times do |i| # 一応2ページ分ほどみておく
        res = @a.get("https://agonp.jp/search?order=latest&page=#{i + 1}")
        programs += parse_programs(res)
        sleep 1
      end
      programs
    end

    def filter_list(programs)
      programs.reject do |program|
        program.price != '無料'
      end
    end

    def parse_programs(page)
      page.search('.search-results__list-item.row').map do |program_row|
        parse_program(program_row)
      end
    end

    def parse_program(program_row)
      title = program_row.css('.search-results__title').first
              .children
              .inner_text.strip
              .sub(/無料\s+/,'')
              .sub(/^\s+/,'')
              .sub(/\s+$/,'')
      episode_id = program_row.css('a.search-results__button--play-latest').attr('href').text.match(/episodes\/view\/(\d+)/)[1]
      Program.new(
          title,
          program_row.css('.search-results__personality').first.text.strip.gsub('／', ' '),
          episode_id,
          program_row.css('.search-results__price').first.text.strip
      )
    end
  end
end
