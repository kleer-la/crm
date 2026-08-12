require "test_helper"

class WelcomeMessageJobTest < ActiveSupport::TestCase
  setup do
    @conversation = create(:conversation, platform: :whatsapp)
  end

  test "sends the welcome message" do
    canned = create(:canned_response, :welcome)

    assert_difference -> { Message.count }, 1 do
      WelcomeMessageJob.perform_now(@conversation)
    end

    welcome = @conversation.messages.last
    assert_equal "outbound", welcome.direction
    assert_equal "text", welcome.message_type
    assert_equal canned.content, welcome.content
  end

  test "skips when no welcome canned response is configured" do
    assert_no_difference -> { Message.count } do
      WelcomeMessageJob.perform_now(@conversation)
    end
  end

  test "skips when the conversation already has an outbound message" do
    create(:canned_response, :welcome)
    create(:message, :outbound, conversation: @conversation)

    assert_no_difference -> { Message.count } do
      WelcomeMessageJob.perform_now(@conversation)
    end
  end

  test "sends even when inbound messages exist" do
    create(:canned_response, :welcome)
    create(:message, conversation: @conversation)

    assert_difference -> { Message.count }, 1 do
      WelcomeMessageJob.perform_now(@conversation)
    end
  end
end
