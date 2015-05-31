module NiconicoLive
  class Downloading
    CH_NAME = 'niconama'

    class NiconamaDownloadException < StandardError; end

    def download(program)
      @program = program
      begin
        setup
        reservation
      rescue Niconico::Live::TicketRetrievingFailed => e
        Rails.logger.error e.class
        Rails.logger.error e.inspect
        Rails.logger.error e.backtrace.join("\n")
        return NiconicoLiveProgram::STATE[:failed_ticket_retrive_failed]
      rescue => e
        Rails.logger.error e.class
        Rails.logger.error e.inspect
        Rails.logger.error e.backtrace.join("\n")
        return NiconicoLiveProgram::STATE[:failed_before_got_rtmp_url]
      end

      begin
        _download
      rescue => e
        Rails.logger.error e.class
        Rails.logger.error e.inspect
        Rails.logger.error e.backtrace.join("\n")
        return NiconicoLiveProgram::STATE[:failed_dumping_rtmp]
      end
      NiconicoLiveProgram::STATE[:done]
    end

    def setup
      @n = Niconico.new(Settings.niconico.username, Settings.niconico.password)
      @n.login
      @c = @n.live_client
      @a = Niconico::Live::API.new(@n.agent)
      remove_timeshifts
      @l = @n.live(@program.id)
      @l.get
    end

    def remove_timeshifts
      ids = @a.watching_reservations.delete_if do |id|
        Niconico::Live::Util::normalize_id(id) ==
        Niconico::Live::Util::normalize_id(@program.id)
      end
      @c.remove_timeshifts(ids)
    end

    def reservation
      begin
        @l.accept_reservation
      rescue Mechanize::ResponseCodeError => e
        # ignore
      end

      # fetch lazy load objects
      @l.quesheet
    end

    def _download
      Main::prepare_working_dir(CH_NAME)

      path = filepath(@l)
      succeed_count = 0
      @l.rtmpdump_commands(path).each do |command|
        sleep 10
        full_file_path = command[3] # super magic number!
        command.delete('-V')
        commnad_str = command.join(' ') + " 2>&1"
        until Main::check_file_size
          Rails.logger.error "downloaded file is not valid: #{@l.id}, #{full_file_path} but continue other file donload"
          next
        end
        Main::shell_exec(commnad_str)
        Main::move_to_archive_dir(CH_NAME, @l.opens_at, full_file_path)
        succeed_count += 1
      end
      if succeed_count == 0
        raise NiconamaDownloadException, "download failed."
      end
    end

    def filepath(live)
      date = live.opens_at.strftime('%Y_%m_%d')
      title = "#{date}_#{live.title}"
      Main::file_path_working_base(CH_NAME, title)
    end
  end
end
