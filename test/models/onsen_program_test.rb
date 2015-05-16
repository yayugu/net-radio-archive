require 'test_helper'

class OnsenProgramTest < ActiveSupport::TestCase
  test "save" do
    p = OnsenProgram.new
    p.title = 'onsen test title'
    p.number = 1
    p.date = DateTime.now
    p.file_url = 'http://test.onsen_program.com'
    p.personality = '花澤香菜'
    p.state = OnsenProgram::STATE[:waiting]
    assert p.save, p.errors.messages
  end
end
