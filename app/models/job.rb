class Job < ActiveRecord::Base
  CH = {
    ag: 'ag',
  }
  STATE = {
    scheduled: 'scheduled',
    recording: 'recording',
    converting: 'converting',
    done: 'done',
    failed: 'failed',
  }

  def length_sec
    (self.end - self.start).to_i
  end
end
