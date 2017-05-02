class Niconico
  class Live
    class Util
      class << self
        def normalize_id(id, with_lv: true)
          id = id.to_s

          if with_lv
            id.start_with?('lv') ? id : "lv#{id}"
          else
            id.start_with?('lv') ? id[2..-1] : id
          end
        end

        # タイムシフト予約が存在する場合にのみ取得できる
        def fetch_token(agent)
          page = agent.get('http://live.nicovideo.jp/my_timeshift_list')
          token_tag = page.at('#confirm')
          token_tag ? token_tag.attr('value') : nil
        end

        def fetch_token_for_watching_reservation(agent, id)
          id = normalize_id(id, with_lv: false)
          page = agent.get("http://live.nicovideo.jp/api/watchingreservation?mode=watch_num&vid=#{id}&next_url=")
          page.body.match(/ulck_[0-9]+/)[0]
        end
      end
    end
  end
end
