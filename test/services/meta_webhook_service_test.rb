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

  test "creates separate conversations for same contact on different platforms" do
    wa_payload = whatsapp_payload("text", { "body" => "WhatsApp message" })
    MetaWebhookService.process(wa_payload)

    ig_payload = instagram_payload("text", { "text" => "Instagram message" })
    MetaWebhookService.process(ig_payload)

    wa_conv = Conversation.find_by(platform: :whatsapp, external_contact_id: "5491155500001")
    ig_conv = Conversation.find_by(platform: :instagram, external_contact_id: "ig_sender_001")
    assert_not_nil wa_conv
    assert_not_nil ig_conv
    assert_not_equal wa_conv, ig_conv
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

  test "rejects duplicate external_message_id" do
    payload = whatsapp_payload_with_id("text", { "body" => "Hello" }, "wamid.dup_test")

    MetaWebhookService.process(payload)

    assert_raises(ActiveRecord::RecordNotUnique) do
      MetaWebhookService.process(payload)
    end
  end

  test "processes audio message" do
    payload = whatsapp_payload("audio", { "id" => "audio_1" })

    results = MetaWebhookService.process(payload)
    message = results.first.message

    assert_equal "audio", message.message_type
    assert_equal "[Audio]", message.content
  end

  test "processes video message with caption" do
    payload = whatsapp_payload("video", { "caption" => "My video", "id" => "vid_1" })

    results = MetaWebhookService.process(payload)
    message = results.first.message

    assert_equal "video", message.message_type
    assert_equal "My video", message.content
  end

  test "processes video message without caption" do
    payload = whatsapp_payload("video", { "id" => "vid_1" })

    results = MetaWebhookService.process(payload)
    assert_equal "[Video]", results.first.message.content
  end

  test "processes document message" do
    payload = whatsapp_payload("document", { "filename" => "report.pdf", "id" => "doc_1" })

    results = MetaWebhookService.process(payload)
    message = results.first.message

    assert_equal "document", message.message_type
    assert_equal "report.pdf", message.content
  end

  test "processes document message without filename" do
    payload = whatsapp_payload("document", { "id" => "doc_1" })

    results = MetaWebhookService.process(payload)
    assert_equal "[Document]", results.first.message.content
  end

  test "processes sticker message" do
    payload = whatsapp_payload("sticker", { "id" => "sticker_1" })

    results = MetaWebhookService.process(payload)
    message = results.first.message

    assert_equal "sticker", message.message_type
    assert_equal "[Sticker]", message.content
  end

  test "processes location message" do
    payload = whatsapp_payload("location", { "latitude" => -34.6037, "longitude" => -58.3816 })

    results = MetaWebhookService.process(payload)
    message = results.first.message

    assert_equal "location", message.message_type
    assert_equal "[Location: -34.6037, -58.3816]", message.content
  end

  test "processes reaction message" do
    payload = whatsapp_payload("reaction", { "emoji" => "👍", "message_id" => "wamid.orig" })

    results = MetaWebhookService.process(payload)
    message = results.first.message

    assert_equal "reaction", message.message_type
    assert_equal "👍", message.content
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

  def instagram_payload(msg_type, type_data)
    {
      "object" => "instagram",
      "entry" => [ {
        "id" => "IG_BIZ_ID",
        "messaging" => [ {
          "sender" => { "id" => "ig_sender_001" },
          "recipient" => { "id" => "IG_BIZ_ID" },
          "timestamp" => (Time.current.to_f * 1000).to_i,
          "message" => {
            "mid" => "igmid.#{SecureRandom.hex(8)}",
            "text" => type_data["body"] || type_data["text"] || "[Message]",
            "attachments" => [ { "type" => msg_type } ]
          }
        } ]
      } ]
    }
  end

  def whatsapp_payload_with_id(msg_type, type_data, message_id)
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
              "id" => message_id,
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
