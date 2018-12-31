require 'shellwords'
require 'fileutils'
require 'm3u8'
require 'uri'

module Hibiki
  class Downloading
    CH_NAME = 'hibiki'

    class HibikiDownloadException < StandardError; end

    def initialize
      @a = Mechanize.new
      @a.user_agent_alias = 'Windows Chrome'
    end

    def download(program)
      infos = get_infos(program)
      actual_episode_id = infos.try(:[], 'episode').try(:[], 'id')
      if actual_episode_id == nil
        program.state = HibikiProgramV2::STATE[:not_downloadable]
        return
      end
      if actual_episode_id != program.episode_id
        Rails.logger.error("episode outdated. title=#{program.title} expected_episode_id=#{program.episode_id} actual_episode_id=#{actual_episode_id}")
        program.state = HibikiProgramV2::STATE[:outdated]
        return
      end
      live_flg = infos['episode'].try(:[], 'video').try(:[], 'live_flg')
      if live_flg == nil || live_flg == true
        program.state = HibikiProgramV2::STATE[:not_downloadable]
        return
      end
      url = get_m3u8_url(infos['episode']['video']['id'])

      prepare_working_dir(program)
      path = process_m3u8(program, url)
      unless download_hls(program, path)
        clean_working_dir(program)
        program.state = HibikiProgramV2::STATE[:failed]
        return
      end
      clean_working_dir(program)
      program.state = HibikiProgramV2::STATE[:done]
    end

    def get_infos(program)
      res = get_api("https://vcms-api.hibiki-radio.jp/api/v1/programs/#{program.access_id}")
      infos = JSON.parse(res.body)
    end

    def get_m3u8_url(video_id)
      res = get_api("https://vcms-api.hibiki-radio.jp/api/v1/videos/play_check?video_id=#{video_id}")
      play_infos = JSON.parse(res.body)
      url = play_infos['playlist_url']
      if play_infos['token']
        url += "&token=#{play_infos['token']}"
      end
      url
    end

    def process_m3u8(program, m3u8_url)

      playlist_m3u8 = get_api(m3u8_url).body
      playlist = M3u8::Playlist.read(playlist_m3u8)

      ts_audio_m3u8_url = playlist.items.first.uri
      if ts_audio_m3u8_url =~ %r(^https://ad.hibiki-radio.jp/m3u8/dynamic_media)
        uri = URI(ts_audio_m3u8_url)
        queries = URI::decode_www_form(uri.query).to_h
        ts_audio_m3u8_url = queries['url2']
      end
      ts_audio_m3u8 = get_api(ts_audio_m3u8_url).body
      ts_audio = M3u8::Playlist.read(ts_audio_m3u8)

      uri = URI.parse(ts_audio_m3u8_url)
      path = "#{uri.scheme}://#{uri.host}#{File.dirname(uri.path)}/"

      ts_audio.items.each do |item|
        if item.kind_of?(M3u8::KeyItem)
          key_url = item.uri
          key_body = get_api(key_url).body.force_encoding('BINARY')
          key_path = working_dir(program) + 'key'
          IO.binwrite(key_path, key_body)
          item.uri = "file:/#{key_path}"
        elsif item.kind_of?(M3u8::SegmentItem)
          url = path + item.segment
          dst_path = working_dir(program) + item.segment
          download_ts(url, dst_path)
          item.segment = "file:/#{dst_path}"
        end
      end

      m3u8_path = working_dir(program) + 'ts_audio.m3u8'
      File.write(m3u8_path, ts_audio.to_s)
      m3u8_path
    end

    def download_ts(url, dst_path)
      command = "curl \
        --silent \
        --show-error \
        --connect-timeout 10 \
        --max-time 30 \
        --retry 5 \
        #{Shellwords.escape(url)} \
        -o #{Shellwords.escape(dst_path)} \
      2>&1"
      exit_status, output = Main::shell_exec(command)
      unless exit_status.success?
        Raise HibikiDownloadException, "ts download faild, hibiki program:#{program.id}, exit_status:#{exit_status}, output:#{output}"
      end
    end

    def download_hls(program, m3u8_path)
      file_path = Main::file_path_working(CH_NAME, title(program), 'mp4')
      arg = "\
        -loglevel error \
        -y \
        -allowed_extensions ALL \
        -protocol_whitelist file,crypto,http,https,tcp,tls \
        -i #{Shellwords.escape(m3u8_path)} \
        -timeout 10000000 \
        -vcodec copy -acodec copy -bsf:a aac_adtstoasc \
        #{Shellwords.escape(file_path)}"

      exit_status, output = Main::ffmpeg_with_timeout('5h', '1m', arg)
      unless exit_status.success?
        Rails.logger.error "rec failed. hibiki program:#{program.id}, exit_status:#{exit_status}, output:#{output}"
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

    def working_dir(program)
      "#{Settings.working_dir}/#{CH_NAME}/#{program.id}/"
    end

    def prepare_working_dir(program)
      FileUtils.mkdir_p(working_dir(program))
    end

    def clean_working_dir(program)
      FileUtils.rm_rf(working_dir(program))
    end
  end
end
