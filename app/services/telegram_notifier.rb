class TelegramNotifier
  def self.notify(text)
    new.notify(text)
  end

  def notify(text)
    token = ENV["TELEGRAM_BOT_TOKEN"]
    chat_id = ENV["TELEGRAM_CHAT_ID"]
    if token.blank? || chat_id.blank?
      Rails.logger.info("[TelegramNotifier] TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID not configured, skipping notification.")
      return false
    end

    uri = URI("https://api.telegram.org/bot#{token}/sendMessage")
    response = post_json(uri, {
      chat_id: chat_id,
      text: text,
      parse_mode: "HTML",
      disable_web_page_preview: true
    })

    return true if response.is_a?(Net::HTTPSuccess)

    Rails.logger.error("[TelegramNotifier] sendMessage failed: HTTP #{response.code} #{response.body.to_s.truncate(200)}")
    false
  end

  private

  def post_json(uri, body)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = body.to_json

    http.request(request)
  end
end
