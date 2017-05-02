# coding: utf-8
require 'niconico/live'
require 'niconico/live/api'

class Niconico
  def live_mypage
    Niconico::Live::Mypage.new(self)
  end

  class Live
    class Mypage
      class UnknownStatus < Exception; end
      URL = 'http://live.nicovideo.jp/my'.freeze

      def initialize(client)
        @client = client
      end

      attr_reader :client

      def agent
        client.agent
      end

      def page
        @page ||= agent.get(URL)
      end

      def reservations
        return @reservations if @reservations
        lists = page.search("form[name=timeshift_list] .liveItems")
        @reservations = lists.flat_map do |list|
          list.search('.column').map do |column|
            link = column.at('.name a')
            id = link[:href].sub(/\A.*\//,'').sub(/\?.*\z/,'')
            status = column.at('.status').inner_text 
            watch_button = column.at('.timeshift_watch a')

            preload = {}

            preload[:title] = link[:title]

            preload[:reservation] = Live::API.parse_reservation_message(status)
            raise UnknownStatus, "BUG, there's unknown message for reservation status: #{status.inspect}" unless preload[:reservation]

            # (試聴する) [試聴期限未定]
            if watch_button && watch_button[:onclick] && watch_button[:onclick].include?('confirm_watch_my')
              preload[:reservation][:status] = :reserved
              preload[:reservation][:available] = true
            end

            Niconico::Live.new(client, id, preload)
          end
        end
      end
      alias timeshift_list reservations

      def available_reservations
        reservations.select { |_| _.reservation_available? }
      end

      def unaccepted_reservations
        reservations.select { |_| _.reservation_unaccepted? }
      end
    end
  end
end
