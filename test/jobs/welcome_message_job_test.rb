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

  # 2026-08-12 is a Wednesday; business hours are 9:00-18:00 America/Argentina/Buenos_Aires (UTC-3)
  test "uses the business-hours welcome during working hours" do
    create(:canned_response, :welcome)
    after_hours = create(:canned_response, :welcome_after_hours)

    travel_to Time.utc(2026, 8, 12, 13, 0) do # 10:00 ART, Wednesday
      WelcomeMessageJob.perform_now(@conversation)
    end

    assert_not_equal after_hours.content, @conversation.messages.last.content
  end

  test "uses the after-hours welcome outside working hours" do
    create(:canned_response, :welcome)
    after_hours = create(:canned_response, :welcome_after_hours)

    travel_to Time.utc(2026, 8, 12, 23, 0) do # 20:00 ART, Wednesday
      WelcomeMessageJob.perform_now(@conversation)
    end

    assert_equal after_hours.content, @conversation.messages.last.content
  end

  test "uses the after-hours welcome on weekends" do
    create(:canned_response, :welcome)
    after_hours = create(:canned_response, :welcome_after_hours)

    travel_to Time.utc(2026, 8, 15, 15, 0) do # 12:00 ART, Saturday
      WelcomeMessageJob.perform_now(@conversation)
    end

    assert_equal after_hours.content, @conversation.messages.last.content
  end

  test "falls back to the regular welcome when no after-hours response exists" do
    canned = create(:canned_response, :welcome)

    travel_to Time.utc(2026, 8, 15, 15, 0) do # Saturday
      WelcomeMessageJob.perform_now(@conversation)
    end

    assert_equal canned.content, @conversation.messages.last.content
  end
end
