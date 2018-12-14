require 'shellwords'

module NiconicoLive
  class Downloading
    CH_NAME = 'niconama'

    class NiconamaDownloadException < StandardError; end

    def download(program)
      @program = program

      begin
        _download
      rescue Exception => e
        Rails.logger.error e.class
        Rails.logger.warn e.inspect
        Rails.logger.warn e.backtrace.join("\n")
        program.state = NiconicoLiveProgram::STATE[:failed]
        return
      end
      program.state = NiconicoLiveProgram::STATE[:done]
    end

    def _download
      Main::prepare_working_dir(CH_NAME)

      exit_status, output = Main::shell_exec(livedl_command)
      unless exit_status.success?
        Rails.logger.warn "nico livedl failed: #{@program.id}, #{output}"
      end

      files = Dir.glob("#{Main::file_path_working_base(CH_NAME, '')}*.mp4")
      if files.empty?
        raise NiconamaDownloadException, "download failed: #{@program.title}"
      end

      files.each do |file|
        Main::move_to_archive_dir(CH_NAME, @program.created_at, file)
      end
    end

    def livedl_command
      "\
        livedl \
          -nico-login '#{Shellwords.escape(Settings.niconico.username)},#{Shellwords.escape(Settings.niconico.password)}'\
          -nico-login-only=on \
          -nico-force-reservation=on \
          -nico-format '#{Main::file_path_working_base(CH_NAME, '')}?DAY8? ?HOUR??MINUTE? ?TITLE?' \
          -nico-auto-convert=on \
          -nico-auto-delete-mode 2 \
          -nico-fast-ts \
          lv#{Shellwords.escape(@program.id)} \
        2>&1
      "
    end
  end
end
