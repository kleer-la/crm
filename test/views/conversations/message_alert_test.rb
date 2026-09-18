require "test_helper"

module Conversations
end

class Conversations::MessageAlertTest < ActionView::TestCase
  test "renders the data the message-alerts controller needs" do
    conversation = create(:conversation, contact_name: "Ana Lopez")
    message = create(:message, conversation: conversation, content: "Hola, necesito ayuda")

    render partial: "conversations/message_alert", locals: { message: message }

    assert_includes rendered, %(data-conversation-path="#{conversation_path(conversation)}")
    assert_includes rendered, %(data-sender="Ana Lopez")
    assert_includes rendered, %(data-content="Hola, necesito ayuda")
  end
end
