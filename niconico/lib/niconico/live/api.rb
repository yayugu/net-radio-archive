# coding: utf-8
require 'time'
require 'openssl'
require 'niconico/live/util'

class Niconico
  class Live
    class API
      class NoPublicKeyProvided < Exception; end

      URL_GETPLAYERSTATUS = 'http://ow.live.nicovideo.jp/api/getplayerstatus'.freeze
      URL_WATCHINGRESERVATION_LIST = 'http://live.nicovideo.jp/api/watchingreservation?mode=list'

      def initialize(agent)
        @agent = agent
      end

      attr_reader :agent

      def self.parse_reservation_message(message)
        valid_until_message = message.match(/(?:使用|利用)?期限: (.+?)まで|(?:期限中、何度でも視聴できます|視聴権(?:利用|使用)期限が切れています|タイムシフト利用期間は終了しました)\s*\[(.+?)まで\]/)
        valid_message = message.match(/\[視聴期限未定\]/)

        case
        when message.match(/予約中\s*\[/)
          {status: :reserved, available: false}
        when valid_until_message || valid_message
          {}.tap do |reservation|
            if valid_until_message
              reservation[:expires_at] = Time.parse("#{valid_until_message[1] || valid_until_message[2]} +0900")
            end

            if message.include?('視聴権を使用し、タイムシフト視聴を行いますか？')
              reservation[:status] = :reserved
              reservation[:available] = true
            elsif message.include?('本番組は、タイムシフト視聴を行う事が可能です。') \
                  || message.include?('期限中、何度でも視聴できます')
              reservation[:status] = :accepted
              reservation[:available] = true
            elsif message.include?('タイムシフト視聴をこれ以上行う事は出来ません。') \
                  || message.include?('視聴権の利用期限が過ぎています。') \
                  || message.include?('視聴権利用期限が切れています') \
                  || message.include?('視聴権使用期限が切れています') \
                  || message.include?('タイムシフト利用期間は終了しました') \
                  || message.include?('アーカイブ公開期限は終了しました。')
              reservation[:status] = :outdated
              reservation[:available] = false
            end
          end
        else
          nil
        end
      end

      def get(id)
        id = Util::normalize_id(id)

        page = agent.get("http://live.nicovideo.jp/gate/#{id}")

        comment_area = page.at("#comment_area#{id}").inner_text

        result = {
          title: page.at('h2 span[itemprop="name"]').inner_text,
          id: id,
          description: page.at('.stream_description .text_area').inner_html,
        }

        kaijo = page.search('.kaijo strong').map(&:inner_text)
        result[:opens_at] = Time.parse("#{kaijo[0]} #{kaijo[1]} +0900")
        result[:starts_at] = Time.parse("#{kaijo[0]} #{kaijo[2]} +0900")

        result[:status] = :scheduled if comment_area.include?('開場まで、あと')
        result[:status] = :on_air if comment_area.include?('現在放送中')
        close_message = comment_area.match(/この番組は(.+?)に終了いたしました。/)
        if close_message
          result[:status] = :closed
          result[:closed_at] = Time.parse("#{close_message[1]} +0900")
        end

        result[:reservation] = self.class.parse_reservation_message(comment_area)
        if !result[:reservation] && page.search(".watching_reservation_reserved").any? { |_| _['onclick'].include?(id) }
          result[:reservation] = {status: :reserved, available: false}
        end

        channel = page.at('div.chan')
        if channel
          result[:channel] = {
            name: channel.at('.shosai a').inner_text,
            id: channel.at('.shosai a')['href'].split('/').last,
            link: channel.at('.shosai a')['href'],
          }
        end

        result
      end

      def heartbeat
        raise NotImplementedError
      end

      def get_player_status(id, public_key = nil)
        id = Util::normalize_id(id)
        page = agent.get("http://ow.live.nicovideo.jp/api/getplayerstatus?locale=GLOBAL&lang=ja%2Djp&v=#{id}&seat%5Flocale=JP")
        if page.body[0] == 'c' # encrypted
          page = Nokogiri::XML(decrypt_encrypted_player_status(page.body, public_key))
        end

        status = page.at('getplayerstatus')

        if status['status'] == 'fail'
          error = page.at('error code').inner_text
          return {error: error}
        end

        result = {}

        # Strings
        %w(id title description provider_type owner_name
           bourbon_url full_video kickout_video).each do |key|
          item = status.at(key)
          result[key.to_sym] = item.inner_text if item
        end

        # Integers
        %w(watch_count comment_count owner_id watch_count comment_count).each do |key|
          item = status.at(key)
          result[key.to_sym] = item.inner_text.to_i if item
        end

        # Flags
        %w(is_premium is_reserved is_owner international is_rerun_stream is_archiveplayserver
           archive allow_netduetto
           is_nonarchive_timeshift_enabled is_timeshift_reserved).each do |key|
          item = status.at(key)
          result[key.sub(/^is_/,'').concat('?').to_sym] = item.inner_text == '1' if item
        end

        # Datetimes
        %w(base_time open_time start_time end_time).each do |key|
          item = status.at(key)
          result[key.to_sym] = Time.at(item.inner_text.to_i) if item
        end

        rtmp = status.at('rtmp')
        result[:rtmp] = {
          url: rtmp.at('url').inner_text,
          ticket: rtmp.at('ticket').inner_text,
        }

        ms = status.at('ms')
        result[:ms] = {
          address: ms.at('addr').inner_text,
          port:    ms.at('port').inner_text.to_i,
          thread:  ms.at('thread').inner_text,
        }

        quesheet = status.search('quesheet que')
        result[:quesheet] = quesheet.map do |que|
          {vpos: que['vpos'].to_i, mail: que['mail'], name: que['name'], body: que.inner_text}
        end

        result
      end

      def watching_reservations
        page = agent.get(URL_WATCHINGRESERVATION_LIST)
        page.search('vid').map(&:inner_text).map{ |_| Util::normalize_id(_) }
      end

      def accept_watching_reservation(id_)
        id = Util::normalize_id(id_, with_lv: false)

        token = Util::fetch_token_for_watching_reservation(@agent, id)
        page = agent.post("http://live.nicovideo.jp/api/watchingreservation",
                          mode: 'auto_register', vid: id, token: token, '_' => '')

        token = Util::fetch_token_for_watching_reservation(@agent, id)
        page = agent.post("http://live.nicovideo.jp/api/watchingreservation",
                          accept: 'true', mode: 'use', vid: id, token: token)
      end

      def decrypt_encrypted_player_status(body, public_key)
        unless public_key
          raise NoPublicKeyProvided,
            'You should provide proper public key to decrypt ' \
            'encrypted player status'
        end

        lines = body.lines
        pubkey = OpenSSL::PKey::RSA.new(public_key)

        encrypted_shared_key = lines[1].unpack('m*')[0]
        shared_key_raw = pubkey.public_decrypt(encrypted_shared_key)
        shared_key = shared_key_raw.unpack('L>*')[0].to_s

        cipher = OpenSSL::Cipher.new('bf-ecb').decrypt
        cipher.padding = 0
        cipher.key_len = shared_key.size
        cipher.key = shared_key

        encrypted_body = lines[2].unpack('m*')[0]

        body = cipher.update(encrypted_body) + cipher.final
        body.force_encoding('utf-8')
      end
    end
  end
end
