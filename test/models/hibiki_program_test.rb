require 'test_helper'

class HibikiProgramTest < ActiveSupport::TestCase
  test "save" do
    p = HibikiProgram.new
    p.title = 'hibiki test title'
    p.comment = '第123回 1月23日更新!'
    p.rtmp_url = 'rtmpe://test.hibiki_program'
    p.state = HibikiProgram::STATE[:waiting]
    p.retry_count = 0
    assert p.save, p.errors.messages
  end
end
