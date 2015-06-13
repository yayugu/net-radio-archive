class NiconicoLiveProgram < ActiveRecord::Base
  STATE = {
    waiting: 'waiting',
    downloading: 'downloading',
    done: 'done',
    failed: 'failed',
    failed_before_got_rtmp_url: 'failed: before got rtmp url',
    failed_dumping_rtmp: 'failed: dumping rtmp',
  }
  RETRY_LIMIT = 3
end
