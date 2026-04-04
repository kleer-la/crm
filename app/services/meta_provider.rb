class MetaProvider
  def send_message(message)
    conversation = message.conversation

    case conversation.platform
    when "instagram"
      send_instagram_message(conversation, message)
    when "whatsapp"
      send_whatsapp_message(conversation, message)
    when "facebook"
      send_facebook_message(conversation, message)
    else
      MessageDispatcher::Result.new(success: false, error: "Unsupported platform: #{conversation.platform}")
    end
  end

  private

  def send_instagram_message(conversation, message)
    uri = URI("https://graph.instagram.com/v25.0/me/messages")

    body = if message.file.attached?
      {
        recipient: { id: conversation.external_contact_id },
        message: {
          attachment: {
            type: ig_attachment_type(message),
            payload: { url: file_url(message) }
          }
        }
      }
    else
      {
        recipient: { id: conversation.external_contact_id },
        message: { text: message.content }
      }
    end

    response = post_json(uri, body, platform: "instagram")

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      message.update(external_message_id: data["message_id"]) if data["message_id"]
      MessageDispatcher::Result.new(success: true)
    else
      error = parse_error(response)
      Rails.logger.error("[MetaProvider] IG send failed: #{error}")
      MessageDispatcher::Result.new(success: false, error: error)
    end
  end

  def send_whatsapp_message(conversation, message)
    phone_number_id = ENV["META_PHONE_NUMBER_ID"]
    unless phone_number_id.present?
      return MessageDispatcher::Result.new(success: false, error: "META_PHONE_NUMBER_ID not configured")
    end

    uri = URI("https://graph.facebook.com/v25.0/#{phone_number_id}/messages")
    body = {
      messaging_product: "whatsapp",
      to: conversation.external_contact_id,
      type: "text",
      text: { body: message.content }
    }

    response = post_json(uri, body)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      wa_message_id = data.dig("messages", 0, "id")
      message.update(external_message_id: wa_message_id) if wa_message_id
      MessageDispatcher::Result.new(success: true)
    else
      error = parse_error(response)
      Rails.logger.error("[MetaProvider] WA send failed: #{error}")
      MessageDispatcher::Result.new(success: false, error: error)
    end
  end

  def send_facebook_message(conversation, message)
    # Facebook Messenger uses the same API pattern as Instagram
    uri = URI("https://graph.facebook.com/v25.0/me/messages")
    body = {
      recipient: { id: conversation.external_contact_id },
      message: { text: message.content }
    }

    response = post_json(uri, body)

    if response.is_a?(Net::HTTPSuccess)
      MessageDispatcher::Result.new(success: true)
    else
      error = parse_error(response)
      Rails.logger.error("[MetaProvider] FB send failed: #{error}")
      MessageDispatcher::Result.new(success: false, error: error)
    end
  end

  def post_json(uri, body, platform: nil)
    token = token_for(platform)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "application/json"
    request.body = body.to_json

    http.request(request)
  end

  def token_for(platform)
    case platform
    when "instagram"
      ENV["META_IG_ACCESS_TOKEN"].presence || ENV["META_ACCESS_TOKEN"]
    else
      ENV["META_ACCESS_TOKEN"]
    end
  end

  def parse_error(response)
    data = JSON.parse(response.body)
    data.dig("error", "message") || "HTTP #{response.code}"
  rescue JSON::ParserError
    "HTTP #{response.code}: #{response.body.to_s.truncate(200)}"
  end

  def file_url(message)
    Rails.application.routes.url_helpers.rails_blob_url(message.file, host: ENV.fetch("APP_HOST", "crm.kleer.la"), protocol: "https")
  end

  def ig_attachment_type(message)
    case message.message_type
    when "image" then "image"
    when "video" then "video"
    when "audio" then "audio"
    else "file"
    end
  end
end
