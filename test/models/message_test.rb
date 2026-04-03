require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "valid message" do
    message = build(:message)
    assert message.valid?
  end

  test "requires conversation" do
    message = build(:message, conversation: nil)
    assert_not message.valid?
  end

  test "requires direction" do
    message = build(:message, direction: nil)
    assert_not message.valid?
    assert_includes message.errors[:direction], "can't be blank"
  end

  test "requires sent_at" do
    message = build(:message, sent_at: nil)
    assert_not message.valid?
    assert_includes message.errors[:sent_at], "can't be blank"
  end

  test "requires content for text messages" do
    message = build(:message, message_type: :text, content: nil)
    assert_not message.valid?
    assert_includes message.errors[:content], "can't be blank"
  end

  test "does not require content for non-text messages" do
    message = build(:message, message_type: :image, content: nil)
    assert message.valid?
  end

  test "updates conversation last_message_at on create" do
    conversation = create(:conversation, last_message_at: 1.day.ago)
    now = Time.current
    create(:message, conversation: conversation, sent_at: now)

    assert_in_delta now.to_f, conversation.reload.last_message_at.to_f, 1
  end

  test "requires content for note messages" do
    message = build(:message, message_type: :note, content: nil)
    assert_not message.valid?
    assert_includes message.errors[:content], "can't be blank"
  end

  test "note message type is valid" do
    message = build(:message, message_type: :note, content: "Internal note", direction: :outbound)
    assert message.valid?
  end

  test "does not overwrite newer last_message_at" do
    conversation = create(:conversation, last_message_at: Time.current)
    original = conversation.last_message_at

    create(:message, conversation: conversation, sent_at: 2.days.ago)

    assert_in_delta original.to_f, conversation.reload.last_message_at.to_f, 1
  end
end
