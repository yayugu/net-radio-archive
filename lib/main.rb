require 'fileutils'
require 'net/http'

module Main
  def self.retry(limit = 3)
    exception = nil

    limit.times do
      begin
        return yield
      rescue => e
        exception = e
      end
    end
    raise exception
  end

  def self.sleep_until(time)
    now = Time.now
    if time - now <= 0
      Rails.logger.warn("rec start delayed? until:#{time} now:#{now}")
      return
    end
    sleep(time - Time.now)
  end

  def self.download(url, filename)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      http.request(request) do |response|
        open(filename, 'wb') do |io|
          unless response.kind_of?(Net::HTTPSuccess)
            Rails.logger.error "download error: #{url}, #{response.code}"
            return false
          end

          response.read_body do |chunk|
            io.write chunk
          end
        end
      end
    end
  end

  def self.shell_exec(command)
    output = `#{command}`
    exit_status = $?
    [exit_status, output]
  end

  def self.ffmpeg(arg)
    exit_status, output = shell_exec('hash ffmpeg >/dev/null 2>&1')
    if exit_status == 0 # found ffmpeg command
      shell_exec("ffmpeg " + arg)
    else
      shell_exec("avconv " + arg)
    end
  end

  def self.convert_ffmpeg_to_mp4(src_path, dst_path, debug_obj)
    arg = "-loglevel error -y -i #{Shellwords.escape(src_path)} -acodec copy -vcodec copy #{Shellwords.escape(dst_path)}"
    convert_ffmpeg_to(arg, debug_obj)
  end

  def self.convert_ffmpeg_to_m4a(src_path, dst_path, debug_obj)
    arg = "-loglevel error -y -i #{Shellwords.escape(src_path)} -acodec copy #{Shellwords.escape(dst_path)}"
    convert_ffmpeg_to(arg, debug_obj)
  end

  def self.convert_ffmpeg_to(arg, debug_obj)
    exit_status, output = ffmpeg(arg)
    unless exit_status.success?
      Rails.logger.error "convert failed. debug_obj:#{debug_obj.inspect}, exit_status:#{exit_status}, output:#{output}"
      return false
    end
    true
  end

  def self.prepare_working_dir(ch_name)
    FileUtils.mkdir_p("#{Settings.working_dir}/#{ch_name}")
  end

  def self.latest_dir_name
    '0_latest'
  end

  def self.move_to_archive_dir(ch_name, date, src)
    filename = File.basename(src)
    dst_dir = "#{Settings.archive_dir}/#{ch_name}/#{month_str(date)}"
    dst = "#{dst_dir}/#{filename}"
    latest_dir = "#{Settings.archive_dir}/#{ch_name}/#{latest_dir_name}"
    latest_symlink = "#{latest_dir}/#{filename}"

    FileUtils.mkdir_p(dst_dir)
    FileUtils.mv(src, dst)

    # create symlink
    FileUtils.mkdir_p(latest_dir)
    unless File.exist?(latest_symlink)
      FileUtils.ln_s(dst, latest_symlink)
    end
  end

  def self.file_path_archive(ch_name, title, ext)
    "#{Settings.archive_dir}/#{ch_name}/#{title_escape(title)}.#{ext}"
  end

  def self.file_path_working(ch_name, title, ext, date = nil)
    if date
      "#{Settings.working_dir}/#{ch_name}/#{month_str(date)}/#{title_escape(title)}.#{ext}"
    else
      "#{Settings.working_dir}/#{ch_name}/#{title_escape(title)}.#{ext}"
    end
  end

  def self.file_path_working_base(ch_name, title)
    "#{Settings.working_dir}/#{ch_name}/#{title_escape(title)}"
  end

  def self.title_escape(title)
    title
      .gsub(/\s/, '_')
      .gsub(/\//, '_')
      .byteslice(0, 200).scrub('') # safe length for filename
  end

  def self.month_str(date)
    date.strftime('%Y%m')
  end

  def self.check_file_size(path, expect_larger_than = (1024 * 1024))
    size = File.size?(path)
    size && size > expect_larger_than
  end
end
