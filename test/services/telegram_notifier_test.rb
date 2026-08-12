require "test_helper"

class TelegramNotifierTest < ActiveSupport::TestCase
  teardown do
    ENV.delete("TELEGRAM_BOT_TOKEN")
    ENV.delete("TELEGRAM_CHAT_ID")
  end

  test "skips without posting when credentials are not configured" do
    notifier = TelegramNotifier.new
    notifier.define_singleton_method(:post_json) { |*| raise "should not post" }

    assert_not notifier.notify("hello")
  end

  test "posts the message to the telegram api" do
    ENV["TELEGRAM_BOT_TOKEN"] = "bot_token_123"
    ENV["TELEGRAM_CHAT_ID"] = "-100999"

    notifier = TelegramNotifier.new
    captured_uri = nil
    captured_body = nil

    notifier.define_singleton_method(:post_json) do |uri, body|
      captured_uri = uri
      captured_body = body
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, { ok: true }.to_json)
      response
    end

    assert notifier.notify("hello <b>team</b>")
    assert_equal "https://api.telegram.org/botbot_token_123/sendMessage", captured_uri.to_s
    assert_equal "-100999", captured_body[:chat_id]
    assert_equal "hello <b>team</b>", captured_body[:text]
    assert_equal "HTML", captured_body[:parse_mode]
  end

  test "returns false on api error" do
    ENV["TELEGRAM_BOT_TOKEN"] = "bot_token_123"
    ENV["TELEGRAM_CHAT_ID"] = "-100999"

    notifier = TelegramNotifier.new
    notifier.define_singleton_method(:post_json) do |_uri, _body|
      response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, { ok: false, description: "chat not found" }.to_json)
      response
    end

    assert_not notifier.notify("hello")
  end
end
