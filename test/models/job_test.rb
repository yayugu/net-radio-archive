require 'test_helper'

class JobTest < ActiveSupport::TestCase
  test "save ag" do
    job = Job.new(
      ch: Job::CH[:ag],
      title: 'test ag',
      start: Date.today,
      end: Date.today + 1,
      state: Job::STATE[:scheduled]
    )
    assert job.save, job.errors.messages
  end
end
