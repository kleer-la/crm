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

  test "show marks conversation as read" do
    get conversation_path(@conversation)
    assert_response :success
    read_state = ConversationReadState.find_by(user: @user, conversation: @conversation)
    assert_not_nil read_state
  end

  test "assign updates assigned_user" do
    other_user = create(:user)
    patch assign_conversation_path(@conversation), params: { assigned_user_id: other_user.id }
    assert_redirected_to conversation_path(@conversation)
    assert_equal other_user, @conversation.reload.assigned_user
  end

  test "link links conversation to customer" do
    customer = create(:customer)
    patch link_conversation_path(@conversation), params: { linkable_type: "Customer", linkable_id: customer.id }
    assert_redirected_to conversation_path(@conversation)
    assert_equal customer, @conversation.reload.linkable
  end

  test "close changes status to closed" do
    patch close_conversation_path(@conversation)
    assert_redirected_to conversation_path(@conversation)
    assert @conversation.reload.closed?
  end

  test "reopen changes status to open" do
    @conversation.update!(status: :closed)
    patch reopen_conversation_path(@conversation)
    assert_redirected_to conversation_path(@conversation)
    assert @conversation.reload.open?
  end

  test "index searches by contact name" do
    create(:conversation, contact_name: "Maria Garcia")
    get conversations_path(q: "Maria")
    assert_response :success
    assert_includes response.body, "Maria Garcia"
  end

  test "index shows empty state when no conversations" do
    Conversation.destroy_all
    get conversations_path
    assert_response :success
    assert_includes response.body, "No conversations yet."
  end

  test "older_messages returns older messages" do
    before = 1.hour.ago
    51.times do |i|
      create(:message, conversation: @conversation, sent_at: before - (i + 1).hours)
    end

    get older_messages_conversation_path(@conversation, before: before.iso8601(6))
    assert_response :success
    assert_includes response.body, "Load earlier messages"
    assert_includes response.body, @conversation.messages.order(:sent_at).last.content
  end

  test "index renders platform badges" do
    ig = create(:conversation, :instagram)
    fb = create(:conversation, :facebook)

    get conversations_path(status: "all")
    assert_response :success
    assert_includes response.body, "WA"
    assert_includes response.body, "IG"
    assert_includes response.body, "FB"
  end

  test "show renders contact panel with linked customer" do
    customer = create(:customer, company_name: "Acme Corp")
    @conversation.update!(linkable: customer)

    get conversation_path(@conversation)
    assert_response :success
    assert_includes response.body, "Customer"
    assert_includes response.body, "Acme Corp"
  end

  test "show renders contact panel empty state when unlinked" do
    get conversation_path(@conversation)
    assert_response :success
    assert_includes response.body, "No linked record"
    assert_includes response.body, "Link to"
  end

  test "unauthenticated user cannot access" do
    delete logout_path
    get conversations_path
    assert_redirected_to login_path
  end
end
