class Niconico
  class Live
    class Client
      module SearchFilters
        ONAIR = ':onair:' # 放送中
        RESERVED = ':reserved:' # 放送予定
        CLOSED = ':closed:' # 放送終了

        # joined by 'OR'
        OFFICIAL = ':official:' # 公式
        CHANNEL = ':channel:' # チャンネル
        COMMUNITY = ':community:' # コミュニティ

        HIDE_TS_EXPIRED = ':hidetsexpired:' # タイムシフトが視聴できない番組を表示しない
        NO_COMMUNITY_GROUP = ':nocommunitygroup:' # 同一コミュニティをまとめて表示しない
        HIDE_COM_ONLY = ':hidecomonly:' # コミュニティ限定番組を表示しない
      end
    end
  end
end

