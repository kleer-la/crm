require "test_helper"

class MetaWebhookServiceTest < ActiveSupport::TestCase
  test "processes whatsapp text message" do
    payload = whatsapp_payload("text", { "body" => "Hi there" })

    results = MetaWebhookService.process(payload)
    assert_equal 1, results.size

    result = results.first
    assert_equal "whatsapp", result.conversation.platform
    assert_equal "5491155500001", result.conversation.external_contact_id
    assert_equal "Juan", result.conversation.contact_name
    assert result.conversation.open?

    assert_equal "inbound", result.message.direction
    assert_equal "Hi there", result.message.content
    assert_equal "text", result.message.message_type
  end

  test "processes whatsapp image message" do
    payload = whatsapp_payload("image", { "caption" => "Check this", "id" => "img_1" })

    results = MetaWebhookService.process(payload)
    message = results.first.message

    assert_equal "image", message.message_type
    assert_equal "Check this", message.content
  end

  test "processes whatsapp image without caption" do
    payload = whatsapp_payload("image", { "id" => "img_1" })

    results = MetaWebhookService.process(payload)
    assert_equal "[Image]", results.first.message.content
  end

  test "reuses existing conversation for same contact" do
    existing = create(:conversation, platform: :whatsapp, external_contact_id: "5491155500001")
    payload = whatsapp_payload("text", { "body" => "Hello again" })

    assert_no_difference "Conversation.count" do
      MetaWebhookService.process(payload)
    end

    assert_equal 1, existing.reload.messages.count
  end

  test "updates contact_name on existing conversation" do
    existing = create(:conversation, platform: :whatsapp, external_contact_id: "5491155500001", contact_name: nil)
    payload = whatsapp_payload("text", { "body" => "Hi" })

    MetaWebhookService.process(payload)
    assert_equal "Juan", existing.reload.contact_name
  end

  test "ignores empty entries" do
    payload = { "object" => "whatsapp_business_account", "entry" => [] }

    results = MetaWebhookService.process(payload)
    assert_empty results
  end

  private

  def whatsapp_payload(msg_type, type_data)
    {
      "object" => "whatsapp_business_account",
      "entry" => [ {
        "id" => "BIZ_ID",
        "changes" => [ {
          "value" => {
            "messaging_product" => "whatsapp",
            "metadata" => { "phone_number_id" => "PHONE_ID" },
            "contacts" => [ { "profile" => { "name" => "Juan" }, "wa_id" => "5491155500001" } ],
            "messages" => [ {
              "from" => "5491155500001",
              "id" => "wamid.#{SecureRandom.hex(8)}",
              "timestamp" => Time.current.to_i.to_s,
              "type" => msg_type,
              msg_type => type_data
            } ]
          },
          "field" => "messages"
        } ]
      } ]
    }
  end
end
