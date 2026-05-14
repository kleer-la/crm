require "test_helper"
require "rake"

class SimulateRakeTest < ActiveSupport::TestCase
  setup do
    Rake::Task.clear
    Rails.application.load_tasks
  end

  test "simulate:webhook creates messages" do
    assert_difference "Message.count", 3 do
      Rake::Task["simulate:webhook"].invoke(3)
    end
  end
end
