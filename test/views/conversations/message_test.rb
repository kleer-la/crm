require "test_helper"

module Conversations
end

class Conversations::MessageTest < ActionView::TestCase
  test "renders the timestamp with the local-time controller for client-side timezone conversion" do
    message = build(:message, sent_at: Time.utc(2026, 9, 17, 14, 32))
    render partial: "conversations/message", locals: { message: message }
    assert_includes rendered, 'data-controller="local-time"'
    assert_includes rendered, "data-local-time-iso-value=\"#{message.sent_at.iso8601}\""
  end
end
