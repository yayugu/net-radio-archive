require 'selenium-webdriver'

module Agon
  class Program < Struct.new(:title, :personality, :episode_id, :page_url)
  end

  class Scraping
    def main
      urls = get_episode_page_urls
      get_episode_infos(urls)
    end

    def get_episode_page_urls
      dom = get_dom("http://ondemand.joqr.co.jp/AG-ON/contents/newarrival.php")
      links = dom.css('#right a')
      links.map do |a|
        a['href']
      end
    end

    def get_episode_infos(page_urls)
      page_urls.map do |url|
        sleep(rand(0.5..1.5))
        get_episode_info(url)
      end
    end

    def get_episode_info(page_url)
      dom = get_dom(page_url)
      dom = dom.css('#right')

      title = dom.css('.sinf_title').first.inner_html.gsub(/\<br\>/i, ' ')
      personality = get_personality(dom)
      episode_id = get_episode_id(dom)

      Program.new(title, personality, episode_id, page_url)
    end

    def get_episode_id(dom)
      js = dom.css('a.ply').first['onclick']
      js.match(/episodeid\=([0-9]+)/)[1]
    end

    def get_personality(dom)
      sp = dom.css('span').find do |span|
        span.text.match('出演者')
      end
      sp.next_sibling.text
    end

    private

    def get_dom(url)
      uri = URI.parse(url)
      html = Net::HTTP.get(uri)
      Nokogiri::HTML.parse(html)
    end
  end
end

