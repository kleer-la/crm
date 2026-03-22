require "test_helper"

class ProspectCallbackLoggingTest < ActiveSupport::TestCase
  setup do
    @prospect = create(:prospect, :new_prospect)
  end

  test "prospect creation auto-logs system event" do
    prospect = create(:prospect)
    log = prospect.activity_logs.find_by(entry_type: :system)
    assert log.present?
    assert_includes log.content, "Prospect created"
  end

  test "status change auto-logs system event" do
    assert_difference "ActivityLog.count", 1 do
      @prospect.update!(status: :contacted)
    end

    log = ActivityLog.last
    assert_equal "system", log.entry_type
    assert_includes log.content, "Status changed"
    assert_includes log.content, "contacted"
  end

  test "multiple status changes log separately" do
    initial_count = @prospect.activity_logs.count

    @prospect.update!(status: :contacted)
    count_after_first = @prospect.activity_logs.count
    assert_equal initial_count + 1, count_after_first

    @prospect.update!(status: :qualified)
    count_after_second = @prospect.activity_logs.count
    assert_equal count_after_first + 1, count_after_second
  end

  test "responsible consultant change auto-logs" do
    new_user = create(:user)

    assert_difference "ActivityLog.count", 1 do
      @prospect.update!(responsible_consultant: new_user)
    end

    log = ActivityLog.last
    assert_equal "system", log.entry_type
    assert_includes log.content, "Responsible consultant changed"
    assert_includes log.content, new_user.name
  end

  test "prospect conversion auto-logs" do
    customer = create(:customer)

    # Note: There will be 2 logs - one for status change, one for conversion
    # because the model logs both events
    initial_count = @prospect.activity_logs.count

    @prospect.update!(status: :converted, converted_customer: customer)

    final_count = @prospect.activity_logs.count
    assert final_count > initial_count

    log = @prospect.activity_logs.where(entry_type: :system).last
    assert_equal "system", log.entry_type
    assert_includes log.content, "Converted to customer"
    assert_includes log.content, customer.company_name
  end

  test "last_activity_date updates on touchpoint" do
    old_date = @prospect.last_activity_date
    travel 1.day

    @prospect.log_touchpoint(touchpoint_type: :call, content: "Test call", user: create(:user))
    new_date = @prospect.reload.last_activity_date

    assert new_date > old_date
  end

  test "last_activity_date updates on system event" do
    old_date = @prospect.last_activity_date
    travel 1.day

    @prospect.log_system_event("Test event")
    new_date = @prospect.reload.last_activity_date

    assert new_date > old_date
  end
end
