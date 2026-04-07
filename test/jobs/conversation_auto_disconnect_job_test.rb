require "test_helper"

class ConversationAutoDisconnectJobTest < ActiveSupport::TestCase
  setup do
    @canned = create(:canned_response, :auto_disconnect)
  end

  test "closes idle conversations with last outbound message" do
    conversation = create(:conversation, status: :open, last_message_at: 13.hours.ago)
    create(:message, :outbound, conversation: conversation, sent_at: 13.hours.ago)

    assert_difference -> { Message.count }, 1 do
      ConversationAutoDisconnectJob.perform_now
    end

    conversation.reload
    assert conversation.closed?
    assert_equal @canned.content, conversation.messages.order(sent_at: :desc).first.content
  end

  test "skips conversations where last message is inbound" do
    conversation = create(:conversation, status: :open, last_message_at: 13.hours.ago)
    create(:message, conversation: conversation, direction: :inbound, sent_at: 13.hours.ago)

    assert_no_difference -> { Message.count } do
      ConversationAutoDisconnectJob.perform_now
    end

    assert conversation.reload.open?
  end

  test "skips conversations within timeout window" do
    conversation = create(:conversation, status: :open, last_message_at: 6.hours.ago)
    create(:message, :outbound, conversation: conversation, sent_at: 6.hours.ago)

    assert_no_difference -> { Message.count } do
      ConversationAutoDisconnectJob.perform_now
    end

    assert conversation.reload.open?
  end

  test "skips already closed conversations" do
    conversation = create(:conversation, :closed, last_message_at: 13.hours.ago)
    create(:message, :outbound, conversation: conversation, sent_at: 13.hours.ago)

    assert_no_difference -> { Message.count } do
      ConversationAutoDisconnectJob.perform_now
    end
  end

  test "skips when no auto_disconnect canned response exists" do
    @canned.destroy!
    conversation = create(:conversation, status: :open, last_message_at: 13.hours.ago)
    create(:message, :outbound, conversation: conversation, sent_at: 13.hours.ago)

    assert_no_difference -> { Message.count } do
      ConversationAutoDisconnectJob.perform_now
    end

    assert conversation.reload.open?
  end

  test "dispatches the disconnect message" do
    conversation = create(:conversation, status: :open, last_message_at: 13.hours.ago)
    create(:message, :outbound, conversation: conversation, sent_at: 13.hours.ago)

    ConversationAutoDisconnectJob.perform_now

    disconnect_msg = conversation.messages.order(sent_at: :desc).first
    assert_equal "outbound", disconnect_msg.direction
    assert_equal "text", disconnect_msg.message_type
  end
end
