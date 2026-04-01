require "test_helper"

class Webhooks::KapsoControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["KAPSO_WEBHOOK_SECRET"] = "test_kapso_secret"
  end

  test "receive processes valid whatsapp message" do
    body = kapso_payload.to_json

    assert_difference [ "Conversation.count", "Message.count" ], 1 do
      post webhooks_kapso_path,
        params: body,
        headers: signed_headers(body)
    end

    assert_response :success

    conversation = Conversation.last
    assert_equal "whatsapp", conversation.platform
    assert_equal "+5491155500001", conversation.external_contact_id
    assert_equal "Juan", conversation.contact_name

    message = Message.last
    assert_equal "inbound", message.direction
    assert_equal "Hello!", message.content
    assert_equal "text", message.message_type
  end

  test "receive ignores non-message events" do
    payload = { "event" => "whatsapp.conversation.created", "data" => {} }
    body = payload.to_json

    assert_no_difference "Message.count" do
      post webhooks_kapso_path,
        params: body,
        headers: signed_headers(body)
    end

    assert_response :success
  end

  test "receive rejects request without signature" do
    post webhooks_kapso_path,
      params: kapso_payload.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :unauthorized
  end

  test "receive rejects request with invalid signature" do
    post webhooks_kapso_path,
      params: kapso_payload.to_json,
      headers: {
        "CONTENT_TYPE" => "application/json",
        "X-Webhook-Signature" => "invalid"
      }

    assert_response :unauthorized
  end

  private

  def kapso_payload
    {
      "event" => "whatsapp.message.received",
      "data" => {
        "message" => {
          "id" => "wamid.kapso_test_#{SecureRandom.hex(4)}",
          "timestamp" => Time.current.to_i.to_s,
          "type" => "text",
          "text" => { "body" => "Hello!" },
          "kapso" => {
            "direction" => "inbound",
            "status" => "received",
            "processing_status" => "pending",
            "origin" => "cloud_api",
            "has_media" => false,
            "content" => "Hello!"
          }
        },
        "conversation" => {
          "id" => "conv_123",
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
    }
  end

  def signed_headers(body)
    signature = OpenSSL::HMAC.hexdigest("SHA256", "test_kapso_secret", body)
    {
      "CONTENT_TYPE" => "application/json",
      "X-Webhook-Signature" => signature
    }
  end
end
