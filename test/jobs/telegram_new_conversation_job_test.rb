require "test_helper"

class TelegramNewConversationJobTest < ActiveSupport::TestCase
  setup do
    @notifications = []
    captured = @notifications
    TelegramNotifier.singleton_class.alias_method(:original_notify, :notify)
    TelegramNotifier.define_singleton_method(:notify) { |text| captured << text; true }
  end

  teardown do
    TelegramNotifier.singleton_class.alias_method(:notify, :original_notify)
    TelegramNotifier.singleton_class.remove_method(:original_notify)
  end

  test "notifies with platform, contact name, first message and link" do
    conversation = create(:conversation, platform: :whatsapp, contact_name: "Juan Pérez")
    create(:message, conversation: conversation, content: "Hola, quiero info sobre un curso")

    TelegramNewConversationJob.perform_now(conversation)

    text = @notifications.last
    assert_includes text, "WhatsApp"
    assert_includes text, "Juan Pérez"
    assert_includes text, "Hola, quiero info sobre un curso"
    assert_includes text, "/conversations/#{conversation.id}"
  end

  test "notifies without a message body when the conversation has no inbound yet" do
    conversation = create(:conversation, :instagram, contact_name: "Ana")

    TelegramNewConversationJob.perform_now(conversation)

    text = @notifications.last
    assert_includes text, "Instagram"
    assert_includes text, "Ana"
    assert_includes text, "/conversations/#{conversation.id}"
  end

  test "escapes html in contact name and message content" do
    conversation = create(:conversation, contact_name: "<b>Hacker</b>")
    create(:message, conversation: conversation, content: "1 < 2 & 3 > 2")

    TelegramNewConversationJob.perform_now(conversation)

    text = @notifications.last
    assert_includes text, "&lt;b&gt;Hacker&lt;/b&gt;"
    assert_includes text, "1 &lt; 2 &amp; 3 &gt; 2"
  end
end
