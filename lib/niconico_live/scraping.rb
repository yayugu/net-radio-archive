module NiconicoLive
  class Scraping
    def main
      setup
      search_keyword + search_keyword_category_bulk
    end

    def setup
      @n = Niconico.new(Settings.niconico.username, Settings.niconico.password)
      @n.login
      @c = @n.live_client
    end

    def search_keyword
      keywords = Settings.niconico.live.keywords
      search(keywords)
    end

    def search_keyword_category_bulk
      ret = []
      WikipediaCategoryItem.find_in_batches(batch_size: 10).each do |batches|
        search_word = batches.map do |item|
          item.title
        end.join(' OR ')
        ret_sub = search([search_word])
        ret += ret_sub
        sleep 10
      end
      ret
    end

    def search(keywords)
      keywords.inject([]) do |ret, keyword|
        ret_sub = @c.search(
          keyword,
          [
            Niconico::Live::Client::SearchFilters::CLOSED,
            Niconico::Live::Client::SearchFilters::OFFICIAL,
            Niconico::Live::Client::SearchFilters::CHANNEL,
            Niconico::Live::Client::SearchFilters::HIDE_TS_EXPIRED,
          ]
        )
        ret_sub.map do |pr|
          pr.id = Niconico::Live::Util.normalize_id(pr.id, with_lv: false)
          pr
        end
        ret + ret_sub
      end
    end
  end
end
