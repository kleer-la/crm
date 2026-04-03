require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @conversation = create(:conversation)
  end

  test "create sends outbound text message" do
    assert_difference "Message.count", 1 do
      post conversation_messages_path(@conversation), params: {
        message: { content: "Hello!", message_type: "text" }
      }
    end

    assert_response :ok
    message = Message.last
    assert_equal "Hello!", message.content
    assert message.outbound?
    assert message.text?
    assert_not_nil message.sent_at
  end

  test "create saves internal note" do
    assert_difference "Message.count", 1 do
      post conversation_messages_path(@conversation), params: {
        message: { content: "Internal note", message_type: "note" }
      }
    end

    assert_response :ok
    message = Message.last
    assert message.note?
    assert message.outbound?
  end

  test "create fails with blank content for text" do
    assert_no_difference "Message.count" do
      post conversation_messages_path(@conversation), params: {
        message: { content: "", message_type: "text" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "unauthenticated user cannot create message" do
    delete logout_path
    post conversation_messages_path(@conversation), params: {
      message: { content: "Hello!", message_type: "text" }
    }
    assert_redirected_to login_path
  end
end
