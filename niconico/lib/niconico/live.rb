# coding: utf-8
require 'niconico/deferrable'
require 'niconico/live/api'

class Niconico
  def live(live_id)
    Live.new(self, live_id)
  end

  class Live
    include Niconico::Deferrable

    class ReservationOutdated < Exception; end
    class ReservationNotAccepted < Exception; end
    class TicketRetrievingFailed < Exception; end
    class AcceptingReservationFailed < Exception; end

    class << self
      def public_key
        @public_key ||= begin
          if ENV["NICONICO_LIVE_PUBLIC_KEY"]
            File.read(File.expand_path(ENV["NICONICO_LIVE_PUBLIC_KEY"]))
          else
            nil
          end
        end
      end

      def public_key=(other)
        @public_key = other
      end
    end

    def initialize(parent, live_id, preload = nil)
      @parent = parent
      @agent = parent.agent
      @id = @live_id = live_id
      @client = Niconico::Live::API.new(@agent)

      if preload
        preload_deffered_values(preload)
      else
        get
      end
    end

    attr_reader :id, :live, :ticket
    attr_writer :public_key

    def public_key
      @public_key || self.class.public_key
    end

    def fetched?
      !!@fetched
    end

    def get(force=false)
      return self if @fetched && !force
      @live = @client.get(@live_id)
      @fetched = true
      self
    end

    def seat(force=false)
      return @seat if @seat && !force
      raise ReservationNotAccepted if reserved? && !reservation_accepted?

      @seat = @client.get_player_status(self.id, self.public_key)

      raise TicketRetrievingFailed, @seat[:error] if @seat[:error]

      @seat
    end

    def accept_reservation
      return self if reservation_accepted?
      raise ReservationOutdated if reservation_outdated?

      result = @client.accept_watching_reservation(self.id)
      raise AcceptingReservationFailed unless result

      sleep 3

      # reload
      get(true)

      self
    end

    def inspect
      "#<Niconico::Live: #{id}, #{title}#{fetched? ? '': ' (deferred)'}>"
    end

    lazy :title do
      live[:title]
    end

    lazy :description do
      live[:description]
    end

    lazy :opens_at do
      live[:opens_at]
    end

    lazy :starts_at do
      live[:starts_at]
    end

    lazy :status do
      live[:status]
    end

    def scheduled?
      status == :scheduled
    end

    def on_air?
      status == :on_air
    end

    def closed?
      status == :closed
    end

    lazy :reservation do
      live[:reservation]
    end

    def reserved?
      !!reservation
    end

    def reservation_available?
      reserved? && reservation[:available]
    end

    def reservation_unaccepted?
      reservation_available? && reservation[:status] == :reserved
    end

    def reservation_accepted?
      reserved? && reservation[:status] == :accepted
    end

    def reservation_outdated?
      reserved? && reservation[:status] == :outdated
    end

    def reservation_expires_at
      reserved? ? reservation[:expires_at] : nil
    end

    lazy :channel do
      live[:channel]
    end

    def premium?
      !!seat[:premium?]
    end

    def rtmp_url
      seat[:rtmp][:url]
    end

    def ticket
      seat[:rtmp][:ticket]
    end

    def quesheet
      seat[:quesheet]
    end

    def execute_rtmpdump(file_base, ignore_failure = false)
      rtmpdump_commands(file_base).map do |cmd|
        system *cmd
        retval = $?
        raise RtmpdumpFailed, "#{cmd.inspect} failed" if !retval.success? && !ignore_failure
        [cmd, retval]
      end
    end

    def rtmpdump_infos(file_base)
      file_base = File.expand_path(file_base)

      publishes = quesheet.select{ |_| /^\/publish / =~ _[:body] }.map do |publish|
        publish[:body].split(/ /).tap(&:shift)
      end

      plays = quesheet.select{ |_| /^\/play / =~ _[:body] }

      infos = []
      plays.flat_map.with_index do |play, i|
        cases = play[:body].sub(/^case:/,'').split(/ /)[1].split(/,/)
        publish_id = nil

        publish_id   = cases.find { |_| _.start_with?('premium:') } if premium?
        publish_id ||= cases.find { |_| _.start_with?('default:') }
        publish_id ||= cases[0]

        publish_id = publish_id.split(/:/).last

        contents = publishes.select{ |_| _[0] == publish_id }
        contents.map.with_index do |content, j|
          content = content[1]
          rtmp = "#{self.rtmp_url}/mp4:#{content}"

          seq = 0
          begin
            file = "#{file_base}.#{i}.#{j}.#{seq}.flv"
            seq += 1
          end while File.exist?(file)
          app = URI.parse(self.rtmp_url).path.sub(/^\//,'')
          infos << {
            file_path: file,
            rtmp_url: rtmp,
            ticket: ticket,
            content: content,
            app: app
          }
        end
      infos
      end
    end
  end
end
