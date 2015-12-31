require 'net/http'
require 'json'
require 'cgi/util'

module Wikipedia
  class Scraping
    def main(category)
      members = get_all(category)
      ret = members.map do |m|
        m['title'].gsub(/^(.*) \(.*\)$/, '\1')
      end.delete_if do |t|
        t.match(/^Category:/) ||
          t.match(/^Template:/)
      end
    end

    def get_all(category)
      category_members = []
      continue = nil
      loop do
        r = get(category, continue)
        category_members += r['query']['categorymembers']
        continue = r
          .try(:[], 'continue')
          .try(:[], 'cmcontinue')
        sleep 5
        unless continue
          break
        end
      end
      category_members
    end

    def get(category, continue)
      url_str = "https://ja.wikipedia.org/w/api.php?action=query&list=categorymembers&format=json&cmlimit=500&cmtitle=#{CGI.escape('Category:' + category)}"
      if continue
        url_str += "&cmcontinue=#{CGI.escape(continue)}"
      end

      res = HTTParty.get(url_str)
      JSON.parse(res.body)
    end
  end
end
