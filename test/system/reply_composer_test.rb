require "application_system_test_case"

class ReplyComposerTest < ApplicationSystemTestCase
  setup do
    @canned = create(:canned_response, name: "Greeting", content: "Hello there!")
    @conversation = create(:conversation, :with_messages)
    @user = create(:user)
    sign_in_via_ui(@user)
  end

  test "quick replies dropdown opens and populates textarea" do
    visit conversation_path(@conversation)

    assert_button "Quick replies"
    click_on "Quick replies"
    assert_selector "[data-reply-composer-target='cannedDropdown']", visible: :visible

    click_on "Greeting"
    assert_field "message[content]", with: "Hello there!"
    assert_selector "[data-reply-composer-target='cannedDropdown']", visible: :hidden
  end

  test "quick replies button hidden when no canned responses" do
    CannedResponse.destroy_all
    visit conversation_path(@conversation)
    assert_no_button "Quick replies"
  end

  test "message textarea clears after successful send" do
    visit conversation_path(@conversation)

    find("textarea[name='message[content]']").set("Test message reply")
    click_on "Send"

    assert_field "message[content]", with: ""
  end
end
