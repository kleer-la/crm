require "test_helper"

class Webhooks::MetaControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["META_WEBHOOK_VERIFY_TOKEN"] = "test_verify_token"
    ENV["META_APP_SECRET"] = "test_app_secret"
  end

  # Verification endpoint tests

  test "verify returns challenge when token matches" do
    get webhooks_meta_path, params: {
      "hub.mode" => "subscribe",
      "hub.verify_token" => "test_verify_token",
      "hub.challenge" => "challenge_123"
    }
    assert_response :success
    assert_equal "challenge_123", response.body
  end

  test "verify returns forbidden when token does not match" do
    get webhooks_meta_path, params: {
      "hub.mode" => "subscribe",
      "hub.verify_token" => "wrong_token",
      "hub.challenge" => "challenge_123"
    }
    assert_response :forbidden
  end

  test "verify returns forbidden when mode is not subscribe" do
    get webhooks_meta_path, params: {
      "hub.mode" => "unsubscribe",
      "hub.verify_token" => "test_verify_token",
      "hub.challenge" => "challenge_123"
    }
    assert_response :forbidden
  end

  # Receive endpoint tests

  test "receive processes valid whatsapp message" do
    body = whatsapp_payload.to_json

    assert_difference [ "Conversation.count", "Message.count" ], 1 do
      post webhooks_meta_path,
        params: body,
        headers: signed_headers(body)
    end

    assert_response :success

    conversation = Conversation.last
    assert_equal "whatsapp", conversation.platform
    assert_equal "5491155500001", conversation.external_contact_id
    assert_equal "Juan", conversation.contact_name

    message = Message.last
    assert_equal "inbound", message.direction
    assert_equal "Hello!", message.content
    assert_equal "text", message.message_type
  end

  test "receive rejects request without signature" do
    post webhooks_meta_path,
      params: whatsapp_payload.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :unauthorized
  end

  test "receive rejects request with invalid signature" do
    post webhooks_meta_path,
      params: whatsapp_payload.to_json,
      headers: {
        "CONTENT_TYPE" => "application/json",
        "X-Hub-Signature-256" => "sha256=invalid"
      }

    assert_response :unauthorized
  end

  private

  def whatsapp_payload
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
              "id" => "wamid.test123",
              "timestamp" => Time.current.to_i.to_s,
              "type" => "text",
              "text" => { "body" => "Hello!" }
            } ]
          },
          "field" => "messages"
        } ]
      } ]
    }
  end

  def signed_headers(body)
    signature = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", "test_app_secret", body)}"
    {
      "Content-Type" => "application/json",
      "X-Hub-Signature-256" => signature
    }
  end
end
