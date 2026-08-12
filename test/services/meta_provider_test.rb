require "test_helper"

class MetaProviderTest < ActiveSupport::TestCase
  setup do
    ENV["META_ACCESS_TOKEN"] = "test_token"
    @provider = MetaProvider.new
  end

  teardown do
    ENV.delete("META_ACCESS_TOKEN")
    ENV.delete("META_PHONE_NUMBER_ID")
  end

  test "whatsapp fails without phone number id" do
    conversation = create(:conversation, platform: :whatsapp)
    message = create(:message, :outbound, conversation: conversation)

    result = @provider.send_message(message)
    assert_not result.success
    assert_includes result.error, "META_PHONE_NUMBER_ID"
  end

  test "unsupported platform returns error" do
    conversation = create(:conversation, platform: :whatsapp)
    message = create(:message, :outbound, conversation: conversation)

    # Temporarily change platform to something unsupported
    conversation.update_column(:platform, 99)

    result = @provider.send_message(message)
    assert_not result.success
  end

  test "instagram send builds correct request" do
    conversation = create(:conversation, :instagram, external_contact_id: "ig_user_123")
    message = create(:message, :outbound, conversation: conversation, content: "Test reply")

    # Capture the request instead of making a real HTTP call
    captured_uri = nil
    captured_body = nil

    @provider.define_singleton_method(:post_json) do |uri, body, platform: nil|
      captured_uri = uri
      captured_body = body
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, { message_id: "ig_mid_789" }.to_json)
      response
    end

    result = @provider.send_message(message)
    assert result.success
    assert_equal "https://graph.instagram.com/v25.0/me/messages", captured_uri.to_s
    assert_equal "ig_user_123", captured_body[:recipient][:id]
    assert_equal "Test reply", captured_body[:message][:text]
    assert_equal "ig_mid_789", message.reload.external_message_id
  end

  test "whatsapp send builds correct request" do
    ENV["META_PHONE_NUMBER_ID"] = "phone_456"
    conversation = create(:conversation, platform: :whatsapp, external_contact_id: "5491155500001")
    message = create(:message, :outbound, conversation: conversation, content: "WA reply")

    captured_body = nil

    @provider.define_singleton_method(:post_json) do |uri, body, platform: nil|
      captured_body = body
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, { messages: [ { id: "wamid.abc" } ] }.to_json)
      response
    end

    result = @provider.send_message(message)
    assert result.success
    assert_equal "whatsapp", captured_body[:messaging_product]
    assert_equal "5491155500001", captured_body[:to]
    assert_equal "WA reply", captured_body[:text][:body]
  end

  test "whatsapp send with image attachment builds media request" do
    ENV["META_PHONE_NUMBER_ID"] = "phone_456"
    conversation = create(:conversation, platform: :whatsapp, external_contact_id: "5491155500001")
    message = create(:message, :outbound, conversation: conversation, content: "Look at this", message_type: :image)
    message.file.attach(io: StringIO.new("jpeg-bytes"), filename: "photo.jpg", content_type: "image/jpeg")

    captured_body = capture_whatsapp_send(message)

    assert_equal "image", captured_body[:type]
    assert_includes captured_body[:image][:link], "crm.kleer.la"
    assert_equal "Look at this", captured_body[:image][:caption]
    assert_nil captured_body[:text]
  end

  test "whatsapp media send omits placeholder caption" do
    ENV["META_PHONE_NUMBER_ID"] = "phone_456"
    conversation = create(:conversation, platform: :whatsapp, external_contact_id: "5491155500001")
    message = create(:message, :outbound, conversation: conversation, content: "[Image]", message_type: :image)
    message.file.attach(io: StringIO.new("jpeg-bytes"), filename: "photo.jpg", content_type: "image/jpeg")

    captured_body = capture_whatsapp_send(message)

    assert_nil captured_body[:image][:caption]
  end

  test "whatsapp document send includes filename" do
    ENV["META_PHONE_NUMBER_ID"] = "phone_456"
    conversation = create(:conversation, platform: :whatsapp, external_contact_id: "5491155500001")
    message = create(:message, :outbound, conversation: conversation, content: "[Document]", message_type: :document)
    message.file.attach(io: StringIO.new("pdf-bytes"), filename: "proposal.pdf", content_type: "application/pdf")

    captured_body = capture_whatsapp_send(message)

    assert_equal "document", captured_body[:type]
    assert_equal "proposal.pdf", captured_body[:document][:filename]
  end

  private

  def capture_whatsapp_send(message)
    captured_body = nil
    @provider.define_singleton_method(:post_json) do |uri, body, platform: nil|
      captured_body = body
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, { messages: [ { id: "wamid.abc" } ] }.to_json)
      response
    end

    result = @provider.send_message(message)
    assert result.success
    captured_body
  end
end
