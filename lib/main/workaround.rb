require 'time'

module Main
  module Workaround
    def self.kill_zombie_process
      pids = (`pgrep 'rtmpdump'`).split("\n").map(&:to_i)
      pids.each do |pid|
        elapsed_sec = Time.now.to_i - Time.parse(`ps -o lstart --noheader -p #{pid}`).to_i
        if (60 * 60 * 25) < elapsed_sec # 24 + 1(margin) hours
          Process.kill(:TERM, pid)
          puts "kill pid:#{pid} elapsed_sec:#{elapsed_sec}"
        end
      end
    end
  end
end
