# -*- coding: utf-8 -*-
require 'json'
require 'open-uri'
require 'nokogiri'
require 'niconico/video'

class Niconico
  def channel_videos(ch)
    login unless logged_in?

    rss = Nokogiri::XML(open("http://ch.nicovideo.jp/#{ch}/video?rss=2.0", &:read))

    rss.search('channel item').map do |item|
      title = item.at('title').inner_text
      link = item.at('link').inner_text
      Video.new(self, link.sub(/^.+\/watch\//, ''), title: title)
    end
  end
end
