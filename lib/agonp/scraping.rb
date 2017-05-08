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
      page.search('.program-list-row').map do |program_row|
        parse_program(program_row)
      end
    end

    def parse_program(program_row)
      title = program_row.css('.program-list-row-title').first
                  .children
                  .select {|c| c.text?}
                  .reduce('') {|memo, c| c.text}
                  .strip
      episode_id = program_row.css('a').first.attr('href')
                       .match(%r{episodes/view/(\d+)})[1]
      Program.new(
          title,
          program_row.css('.program-list-row-participants').first.text.strip.gsub('／', ' '),
          episode_id,
          program_row.css('.program-list-row-price').first.text.strip,
      )
    end
  end
end
