require 'time'

module Main
  module Workaround
    def self.kill_zombie_process
      send_signal_to_zombie_processes('rtmpdump', :TERM)
      send_signal_to_zombie_processes('ffmpeg', :TERM)
      send_signal_to_zombie_processes('avconv', :TERM)
      sleep 5
      send_signal_to_zombie_processes('rtmpdump', :KILL)
      send_signal_to_zombie_processes('ffmpeg', :KILL)
      send_signal_to_zombie_processes('avconv', :KILL)
    end

    def self.rm_working_files
      if Settings.working_dir.strip.size < 2
        puts "working dir is maybe wrong: #{Settings.working_dir}"
        return
      end
      `find #{Settings.working_dir} -ctime +#{Settings.working_files_retention_period_days || 7} -name "*.flv" -exec rm {} \\;`
      `find #{Settings.working_dir} -ctime +#{Settings.working_files_retention_period_days || 7} -name "*.mp3" -exec rm {} \\;`
    end

    def self.rm_latest_dir_symlinks
      if Settings.archive_dir.strip.size < 2
        puts "archive dir is maybe wrong: #{Settings.archive_dir}"
        return
      end
      `find #{Settings.archive_dir}/*/#{Main::latest_dir_name} -ctime +30 -type l -exec rm {} \\;`
    end

    private

    def self.send_signal_to_zombie_processes(process_name, signal)
      pids = (`pgrep '#{process_name}'`).split("\n").map(&:to_i)
      pids.each do |pid|
        elapsed_sec = Time.now.to_i - Time.parse(`ps -o lstart --noheader -p #{pid}`).to_i
        if (60 * 60 * 25) < elapsed_sec # 24 + 1(margin) hours
          Process.kill(signal, pid)
          puts "kill pid:#{pid} elapsed_sec:#{elapsed_sec}"
        end
      end
    end
  end
end
