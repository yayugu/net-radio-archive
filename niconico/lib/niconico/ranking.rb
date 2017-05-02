# -*- coding: utf-8 -*-

class Niconico
  # options[:span]    -> :hourly, :daily, :weekly, :monthly, :total
  #                or -> :hour, :day, :week, :month, :all
  #   default: daily
  #
  # options[:method] -> :fav,     :view, :comment, :mylist
  #                     (or :all)        (or :res)
  def ranking(category = 'all', options={})
    login unless logged_in?

    span = options[:span] || :daily
    span = :hourly  if span == :hour
    span = :daily   if span == :day
    span = :weekly  if span == :week
    span = :monthly if span == :month
    span = :total   if span == :all

    method = options[:method] || :fav
    method = :res if method == :comment
    method = :fav if method == :all

    page = @agent.get(url = "http://www.nicovideo.jp/ranking/#{method}/#{span}/#{category}")
    page.search(".ranking.itemTitle a").map do |link|
      Video.new(self, link['href'].sub(/^.*?watch\//,""), title: link.inner_text)
    end
  end
end
