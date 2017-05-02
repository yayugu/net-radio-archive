# -*- coding: utf-8 -*-
require 'json'

class Niconico
  def mylist(i)
    login unless logged_in?

    page = @agent.get(url = "http://www.nicovideo.jp/mylist/#{i.to_s.sub(/^mylist\//,"")}")
    #require 'ir_b'; ir b
    if page.search("script").map(&:inner_text).find{|x| /\tMylist\.preload/ =~ x }.match(/\tMylist\.preload\(\d+, (.+?)\);\n/)
      json = JSON.parse($1)
      #require 'pp'; pp json
      json.sort_by{|item| item["create_time"].to_f }.map do |item|
        Video.new(self, item["item_data"]["video_id"],
                  title: item["item_data"]["title"],
                  mylist_comment: item["description"])
      end
    else
      raise MylistParseError
    end
  end

  class MylistParseError < Exception; end
end
