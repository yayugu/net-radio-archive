require 'json'

class Niconico
  class NicoAPI
    class AcquiringTokenError < Exception; end
    class ApiError < Exception
      def initialize(error)
        @description = error['description']
        @code = error['code']
        super "#{@code}: #{@description.inspect}"
      end

      attr_reader :code, :description
    end

    MYLIST_ITEM_TYPES = {video: 0, seiga: 5}

    def initialize(parent)
      @parent = parent
    end

    def agent; @parent.agent; end

    def token; @token ||= get_token; end

    def get_token
      page = agent.get(Niconico::URL[:my_mylist])
      match = page.search("script").map(&:inner_text).grep(/\tNicoAPI\.token/) {|v| v.match(/\tNicoAPI\.token = "(.+)";\n/)}.first
      if match
        match[1]
      else
        raise AcquiringTokenError, "Couldn't find a token"
      end
    end

    def mylist_add(group_id, item_type, item_id, description='')
      !!post(
        '/api/mylist/add',
        {
          group_id: group_id,
          item_type: MYLIST_ITEM_TYPES[item_type],
          item_id: item_id,
          description: description,
        }
      )
    end

    private

    def post(path, params)
      retried = false
      begin
        params = params.merge(token: token)
        uri = URI.join(Niconico::URL[:top], path)
        page = agent.post(uri, params)
        json = JSON.parse(page.body)

        raise ApiError.new(json['error']) unless json['status'] == 'ok'

        json
      rescue ApiError => e
        if (e.code == 'INVALIDTOKEN' || e.code == 'EXPIRETOKEN') && !retried
          retried = true
          @token = nil
          retry
        else
          raise e
        end
      end
    end
  end
end
