require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "valid conversation" do
    conversation = build(:conversation)
    assert conversation.valid?
  end

  test "requires platform" do
    conversation = build(:conversation, platform: nil)
    assert_not conversation.valid?
    assert_includes conversation.errors[:platform], "can't be blank"
  end

  test "requires external_contact_id" do
    conversation = build(:conversation, external_contact_id: nil)
    assert_not conversation.valid?
    assert_includes conversation.errors[:external_contact_id], "can't be blank"
  end

  test "external_contact_id unique per platform" do
    create(:conversation, platform: :whatsapp, external_contact_id: "123")
    duplicate = build(:conversation, platform: :whatsapp, external_contact_id: "123")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:external_contact_id], "has already been taken"
  end

  test "same external_contact_id allowed on different platforms" do
    create(:conversation, platform: :whatsapp, external_contact_id: "123")
    other = build(:conversation, platform: :instagram, external_contact_id: "123")
    assert other.valid?
  end

  test "display_name returns contact_name when present" do
    conversation = build(:conversation, contact_name: "Juan")
    assert_equal "Juan", conversation.display_name
  end

  test "display_name falls back to external_contact_id" do
    conversation = build(:conversation, contact_name: nil, external_contact_id: "+5491155500001")
    assert_equal "+5491155500001", conversation.display_name
  end

  test "platform_label returns short codes" do
    assert_equal "WA", build(:conversation, platform: :whatsapp).platform_label
    assert_equal "IG", build(:conversation, platform: :instagram).platform_label
    assert_equal "FB", build(:conversation, platform: :facebook).platform_label
  end

  test "recent scope orders by last_message_at desc" do
    old = create(:conversation, last_message_at: 2.days.ago)
    recent = create(:conversation, last_message_at: 1.hour.ago)

    assert_equal [ recent, old ], Conversation.recent.to_a
  end

  test "has many messages with dependent destroy" do
    conversation = create(:conversation, :with_messages)
    assert_equal 2, conversation.messages.count

    assert_difference "Message.count", -2 do
      conversation.destroy
    end
  end
end
