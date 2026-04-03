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

  test "belongs to assigned_user optionally" do
    conversation = build(:conversation, assigned_user: nil)
    assert conversation.valid?
  end

  test "can be assigned to a user" do
    user = create(:user)
    conversation = create(:conversation, assigned_user: user)
    assert_equal user, conversation.assigned_user
  end

  test "belongs to linkable polymorphic optionally" do
    conversation = build(:conversation, linkable: nil)
    assert conversation.valid?
  end

  test "can be linked to a customer" do
    customer = create(:customer)
    conversation = create(:conversation, linkable: customer)
    assert_equal customer, conversation.linkable
  end

  test "can be linked to a prospect" do
    prospect = create(:prospect)
    conversation = create(:conversation, linkable: prospect)
    assert_equal prospect, conversation.linkable
  end

  test "has many read_states with dependent destroy" do
    conversation = create(:conversation)
    create(:conversation_read_state, conversation: conversation)
    assert_equal 1, conversation.read_states.count

    assert_difference "ConversationReadState.count", -1 do
      conversation.destroy
    end
  end

  test "unread_count_for returns total messages when no read state" do
    conversation = create(:conversation, :with_messages)
    user = create(:user)
    assert_equal 2, conversation.unread_count_for(user)
  end

  test "unread_count_for returns messages after last_read_at" do
    conversation = create(:conversation)
    user = create(:user)
    create(:message, conversation: conversation, sent_at: 2.hours.ago)
    create(:message, conversation: conversation, sent_at: 30.minutes.ago)
    create(:conversation_read_state, user: user, conversation: conversation, last_read_at: 1.hour.ago)

    assert_equal 1, conversation.unread_count_for(user)
  end

  test "mark_as_read creates read state" do
    conversation = create(:conversation)
    user = create(:user)

    assert_difference "ConversationReadState.count", 1 do
      conversation.mark_as_read!(user)
    end
  end

  test "mark_as_read updates existing read state" do
    conversation = create(:conversation)
    user = create(:user)
    create(:conversation_read_state, user: user, conversation: conversation, last_read_at: 1.day.ago)

    assert_no_difference "ConversationReadState.count" do
      conversation.mark_as_read!(user)
    end

    assert_in_delta Time.current, conversation.read_states.find_by(user: user).last_read_at, 2
  end

  test "search_by_contact finds by name" do
    create(:conversation, contact_name: "Carlos Martinez")
    create(:conversation, contact_name: "Ana Lopez")

    results = Conversation.search_by_contact("Carlos")
    assert_equal 1, results.count
    assert_equal "Carlos Martinez", results.first.contact_name
  end
end
