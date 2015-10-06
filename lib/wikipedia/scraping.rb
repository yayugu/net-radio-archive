require 'net/http'
require 'json'

module Wikipedia
  class Scraping
    def main(category)
      members = get_all(category)
      ret = members.map do |m|
        m['title'].gsub(/^(.*) \(.*\)$/, '\1')
      end.delete_if do |t|
        t.match(/^Category:/)
      end
    end

    def get_all(category)
      category_members = []
      continue = nil
      loop do
        r = get(category, continue)
        category_members += r['query']['categorymembers']
        continue = r
          .try(:[], 'query-continue')
          .try(:[], 'categorymembers')
          .try(:[], 'cmcontinue')
        sleep 1
        unless continue
          break
        end
      end
      category_members
    end

    def get(category, continue)
      url_str = "http://ja.wikipedia.org/w/api.php?action=query&list=categorymembers&format=json&cmlimit=500&cmtitle=#{URI.escape('Category:' + category)}"
      if continue
        url_str += "&cmcontinue=#{URI.escape(continue)}"
      end

      ret = Net::HTTP.get(URI(url_str))
      results = JSON.parse(ret)
    end
  end
end
