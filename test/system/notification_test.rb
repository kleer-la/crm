require "application_system_test_case"

class NotificationTest < ApplicationSystemTestCase
  setup do
    @conversation = create(:conversation, :with_messages)
    @user = create(:user)
    sign_in_via_ui(@user)
  end

  test "notification permission banner appears on conversation show" do
    visit conversation_path(@conversation)
    assert_selector "#notification-banner", visible: :visible
    assert_includes page.text, "Enable desktop notifications"
  end

  test "notification permission banner appears app-wide, not just on a conversation" do
    visit conversations_path
    assert_selector "#notification-banner", visible: :visible
  end
end
