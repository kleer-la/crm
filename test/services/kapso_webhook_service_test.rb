require "test_helper"

class KapsoWebhookServiceTest < ActiveSupport::TestCase
  test "processes whatsapp text message" do
    data = kapso_data("text", { "body" => "Hi there" })

    results = KapsoWebhookService.process(data)
    assert_equal 1, results.size

    result = results.first
    assert_equal "whatsapp", result.conversation.platform
    assert_equal "+5491155500001", result.conversation.external_contact_id
    assert_equal "Juan", result.conversation.contact_name
    assert result.conversation.open?

    assert_equal "inbound", result.message.direction
    assert_equal "Hi there", result.message.content
    assert_equal "text", result.message.message_type
  end

  test "processes image message with caption" do
    data = kapso_data("image", { "caption" => "Check this", "id" => "img_1" })

    results = KapsoWebhookService.process(data)
    message = results.first.message

    assert_equal "image", message.message_type
    assert_equal "Check this", message.content
  end

  test "processes image message without caption" do
    data = kapso_data("image", { "id" => "img_1" })

    results = KapsoWebhookService.process(data)
    assert_equal "[Image]", results.first.message.content
  end

  test "reuses existing conversation for same phone number" do
    existing = create(:conversation, platform: :whatsapp, external_contact_id: "+5491155500001")
    data = kapso_data("text", { "body" => "Hello again" })

    assert_no_difference "Conversation.count" do
      KapsoWebhookService.process(data)
    end

    assert_equal 1, existing.reload.messages.count
  end

  test "updates contact_name on existing conversation" do
    existing = create(:conversation, platform: :whatsapp, external_contact_id: "+5491155500001", contact_name: nil)
    data = kapso_data("text", { "body" => "Hi" })

    KapsoWebhookService.process(data)
    assert_equal "Juan", existing.reload.contact_name
  end

  test "returns empty array when message or conversation missing" do
    results = KapsoWebhookService.process({})
    assert_empty results
  end

  private

  def kapso_data(msg_type, type_data)
    {
      "message" => {
        "id" => "wamid.#{SecureRandom.hex(8)}",
        "timestamp" => Time.current.to_i.to_s,
        "type" => msg_type,
        msg_type => type_data,
        "kapso" => {
          "direction" => "inbound",
          "status" => "received",
          "content" => type_data["body"] || "[#{msg_type.capitalize}]"
        }
      },
      "conversation" => {
        "id" => "conv_#{SecureRandom.hex(4)}",
        "phone_number" => "+5491155500001",
        "status" => "active",
        "phone_number_id" => "123456789012345",
        "kapso" => {
          "contact_name" => "Juan",
          "messages_count" => 1
        }
      },
      "is_new_conversation" => true,
      "phone_number_id" => "123456789012345"
    }
  end
end
