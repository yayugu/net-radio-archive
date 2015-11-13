require 'shellwords'
require 'fileutils'

module Hibiki
  class Downloading
    CH_NAME = 'hibiki'

    def initialize
      @a = Mechanize.new
      @a.user_agent_alias = 'Windows Chrome'
    end

    def download(program)
      infos = get_infos(program)
      if infos['episode']['id'] != program.episode_id
        Rails.logger.error("episode outdated. title=#{program.title} expected_episode_id=#{program.episode_id} actual_episode_id=#{infos['episode']['id']}")
        program.state = HibikiProgramV2::STATE[:outdated]
        return
      end
      live_flg = infos['episode'].try(:[], 'video').try(:[], 'live_flg')
      if live_flg == nil || live_flg == true
        program.state = HibikiProgramV2::STATE[:not_downloadable]
        return
      end
      url = get_m3u8_url(infos['episode']['video']['id'])
      unless download_hls(program, url)
        program.state = HibikiProgramV2::STATE[:failed]
        return
      end
      program.state = HibikiProgramV2::STATE[:done]
    end

    def get_infos(program)
      res = get_api("https://vcms-api.hibiki-radio.jp/api/v1/programs/#{program.access_id}")
      infos = JSON.parse(res.body)
    end

    def get_m3u8_url(video_id)
      res = get_api("https://vcms-api.hibiki-radio.jp/api/v1/videos/play_check?video_id=#{video_id}")
      play_infos = JSON.parse(res.body)
      play_infos['playlist_url']
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
      if output.present?
        Rails.logger.warn "hibiki ffmpeg command:#{arg} output:#{output}"
      end

      Main::move_to_archive_dir(CH_NAME, program.created_at, file_path)

      true
    end

    def get_api(url)
      @a.get(
        url,
        [],
        "http://hibiki-radio.jp/",
        'X-Requested-With' => 'XMLHttpRequest',
        'Origin' => 'http://hibiki-radio.jp'
      )
    end

    def title(program)
      date = program.created_at.strftime('%Y_%m_%d')
      title = "#{date}_#{program.title}_#{program.episode_name}"
      if program.cast.present?
        cast = program.cast.gsub(',', ' ')
        title += "_#{cast}"
      end
      title
    end
  end
end
