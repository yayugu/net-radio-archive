require 'selenium-webdriver'

module Agon
  class Downloading
    CH_NAME = 'agon'

    def initialize
    end

    def download(program)
      begin
        if Settings.agon.headless
          require 'headless'
          headless = Headless.new
          headless.start
        end
        profile = Selenium::WebDriver::Firefox::Profile.new
        profile['general.useragent.override'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_0 like Mac OS X) AppleWebKit/601.1.32 (KHTML, like Gecko) Mobile/13A4254v'
        @s = Selenium::WebDriver.for :firefox, profile: profile

        url = get_m3u8_url(program)
      rescue => e
        Rails.logger.warn e.class
        Rails.logger.warn e.inspect
        Rails.logger.warn e.backtrace.join("\n")
        return false
      end
      download_hls(program, url)
    end

    def get_m3u8_url(program)
      @s.navigate.to "http://ct.uliza.jp/AG-ON/play.aspx?clientid=749&msid=339&episodeid=#{program.episode_id}"
      elm = @s.find_element(:name, 'mail')
      elm.send_keys Settings.agon.mail
      elm = @s.find_element(:name, 'passwd')
      elm.send_keys Settings.agon.password
      @s.find_element(:id, 'btnLogin').click

      m3u8_url = @s.find_element(:tag_name, 'video')['src']
      @s.quit
      return m3u8_url
    end

    def download_hls(program, m3u8_url)
      file_path = Main::file_path_working(CH_NAME, title(program), 'mp4')
      arg = "\
        -loglevel error \
        -y \
        -i #{Shellwords.escape(m3u8_url)} \
        -vcodec copy -acodec copy -bsf:a aac_adtstoasc \
        #{Shellwords.escape(file_path)}"

      Main::prepare_working_dir(CH_NAME)
      exit_status, output = Main::ffmpeg(arg)
      unless exit_status.success?
        Rails.logger.error "rec failed. program:#{program}, exit_status:#{exit_status}, output:#{output}"
        return false
      end

      Main::move_to_archive_dir(CH_NAME, program.created_at, file_path)

      true
    end

    def title(program)
      date = program.created_at.strftime('%Y_%m_%d')
      title = "#{date}_#{program.title}"
      if program.personality
        title += "_#{program.personality}"
      end
      title
    end
  end
end

