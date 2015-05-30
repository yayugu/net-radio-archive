class NiconicoLiveProgram < ActiveRecord::Base
  STATE = {
    waiting: 'waiting',
    downloading: 'downloading',
    done: 'done',
    failed_ticket_retrive_failed: 'failed: ticket_retrive_failed', # 何らかの理由でチケットが取得できなかった。タイムシフト期限切れ、accept_reservationに何らかの理由で失敗など
    failed_before_got_rtmp_url: 'failed: before got rtmp url',
    failed_dumping_rtmp: 'failed: dumping rtmp',
  }
  RETRY_LIMIT = 3
end
