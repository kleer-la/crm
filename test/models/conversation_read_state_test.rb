require "test_helper"

class ConversationReadStateTest < ActiveSupport::TestCase
  test "valid read state" do
    read_state = build(:conversation_read_state)
    assert read_state.valid?
  end

  test "requires last_read_at" do
    read_state = build(:conversation_read_state, last_read_at: nil)
    assert_not read_state.valid?
    assert_includes read_state.errors[:last_read_at], "can't be blank"
  end

  test "unique per user and conversation" do
    existing = create(:conversation_read_state)
    duplicate = build(:conversation_read_state, user: existing.user, conversation: existing.conversation)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "same user can have read states for different conversations" do
    user = create(:user)
    create(:conversation_read_state, user: user)
    other = build(:conversation_read_state, user: user)
    assert other.valid?
  end
end
