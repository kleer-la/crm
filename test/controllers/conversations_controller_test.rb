require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @conversation = create(:conversation, :with_messages)
  end

  test "index lists conversations" do
    get conversations_path
    assert_response :success
    assert_includes response.body, @conversation.display_name
  end

  test "index filters by platform" do
    ig_convo = create(:conversation, :instagram, contact_name: "IG User")

    get conversations_path(platform: "instagram")
    assert_response :success
    assert_includes response.body, "IG User"
    assert_not_includes response.body, @conversation.contact_name
  end

  test "show displays conversation messages" do
    get conversation_path(@conversation)
    assert_response :success
    assert_includes response.body, @conversation.display_name
  end

  test "unauthenticated user cannot access" do
    delete logout_path
    get conversations_path
    assert_redirected_to login_path
  end
end
