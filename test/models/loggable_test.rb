require "test_helper"

class LoggableTest < ActiveSupport::TestCase
  test "log_system_event creates system activity log" do
    prospect = create(:prospect)

    assert_difference "ActivityLog.count", 1 do
      prospect.log_system_event("Test event")
    end

    log = prospect.activity_logs.last
    assert_equal "system", log.entry_type
    assert_equal "Test event", log.content
    assert_nil log.user
  end

  test "log_system_event with user" do
    prospect = create(:prospect)
    user = create(:user)

    prospect.log_system_event("Test event", user: user)

    log = prospect.activity_logs.last
    assert_equal user, log.user
  end

  test "log_touchpoint creates touchpoint activity log" do
    customer = create(:customer)
    user = create(:user)

    assert_difference "ActivityLog.count", 1 do
      customer.log_touchpoint(touchpoint_type: :call, content: "Called client", user: user)
    end

    log = customer.activity_logs.last
    assert_equal "touchpoint", log.entry_type
    assert_equal "call", log.touchpoint_type
    assert_equal "Called client", log.content
    assert_equal user, log.user
  end

  test "activity_logs association works" do
    prospect = create(:prospect)
    prospect.log_system_event("Event 1")
    prospect.log_system_event("Event 2")

    assert_equal 3, prospect.activity_logs.count # 2 manual + 1 from after_commit :log_creation
  end

  test "destroying loggable destroys activity logs" do
    prospect = create(:prospect)
    prospect.log_system_event("Will be destroyed")

    assert_difference "ActivityLog.count", -2 do
      prospect.destroy!
    end
  end
end
