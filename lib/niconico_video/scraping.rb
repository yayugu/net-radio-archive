require 'time'
require 'mechanize'

module NiconicoVideo
  ProgramBase = Struct.new(:video_id, :title)
  class Program < ProgramBase
  end

  class Scraping
    def initialize
      @a = Mechanize.new
      @a.user_agent_alias = 'Windows Chrome'
    end

    def main
      programs = []
      if Settings.niconico.video.channels
        Settings.niconico.video.channels.each do |ch|
          programs += channel_videos(ch)
        end
      end
      programs
    end

    # https://github.com/sorah/niconico/blob/9379c60f08d0c811fcde3f0c0b41c0a579cc2633/lib/niconico/channel.rb#L8
    def channel_videos(ch)
      rss = Nokogiri::XML(open("http://ch.nicovideo.jp/#{ch}/video?rss=2.0", &:read))

      rss.search('channel item').map do |item|
        title = item.at('title').inner_text
        link = item.at('link').inner_text
        Program.new(link.sub(/^.+\/watch\//, ''), title)
      end
    end
  end
end
