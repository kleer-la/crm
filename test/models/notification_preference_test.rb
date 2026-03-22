require "test_helper"

class NotificationPreferenceTest < ActiveSupport::TestCase
  test "valid notification preference" do
    np = build(:notification_preference)
    assert np.valid?
  end

  test "unique per user and notification_type" do
    user = create(:user)
    create(:notification_preference, user: user, notification_type: "task_due_reminder")
    np = build(:notification_preference, user: user, notification_type: "task_due_reminder")
    assert_not np.valid?
  end
end
