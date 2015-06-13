module NiconicoLive
  class Scraping
    def main
      setup
      search
    end

    def setup
      @n = Niconico.new(Settings.niconico.username, Settings.niconico.password)
      @n.login
      @c = @n.live_client
    end

    def search
      keywords = Settings.niconico.live.keywords
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
