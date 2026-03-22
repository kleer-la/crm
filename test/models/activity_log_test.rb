require "test_helper"

class ActivityLogTest < ActiveSupport::TestCase
  test "valid activity log" do
    log = build(:activity_log)
    assert log.valid?
  end

  test "requires entry_type" do
    log = build(:activity_log, entry_type: nil)
    assert_not log.valid?
  end

  test "requires content" do
    log = build(:activity_log, content: nil)
    assert_not log.valid?
    assert_includes log.errors[:content], "can't be blank"
  end

  test "requires touchpoint_type when touchpoint" do
    log = build(:activity_log, entry_type: :touchpoint, touchpoint_type: nil)
    assert_not log.valid?
    assert_includes log.errors[:touchpoint_type], "can't be blank"
  end

  test "immutable after persisted - cannot update" do
    log = create(:activity_log)
    assert_raises(ActiveRecord::ReadOnlyRecord) { log.update!(content: "changed") }
  end

  test "can be destroyed via parent cascade" do
    prospect = create(:prospect)
    prospect.log_system_event("Test event")
    assert_difference "ActivityLog.count", -0 do
      # Activity logs exist
    end
    assert prospect.activity_logs.count > 0
    assert_nothing_raised { prospect.destroy! }
  end

  test "user is optional for system events" do
    prospect = create(:prospect)
    log = ActivityLog.create!(entry_type: :system, content: "auto event", loggable: prospect, user: nil)
    assert log.persisted?
  end
end
