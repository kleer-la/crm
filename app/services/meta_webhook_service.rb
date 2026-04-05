class MetaWebhookService
  Result = Struct.new(:conversation, :message, keyword_init: true)

  def self.process(payload)
    new(payload).process
  end

  def initialize(payload)
    @payload = payload
  end

  def process
    results = []

    entries.each do |entry|
      changes_for(entry).each do |change|
        result = process_change(change)
        results << result if result
      end
    end

    results
  end

  private

  def entries
    @payload.dig("entry") || []
  end

  def changes_for(entry)
    # WhatsApp uses "changes", Messenger/IG use "messaging"
    entry["changes"] || entry["messaging"] || []
  end

  def process_change(change)
    if whatsapp_message?(change)
      process_whatsapp_message(change)
    elsif messenger_message?(change)
      process_messenger_message(change)
    end
  end

  def instagram?
    @payload["object"] == "instagram"
  end

  def page_id
    @payload.dig("entry", 0, "id")
  end

  def whatsapp_message?(change)
    value = change["value"]
    value && value["messaging_product"] == "whatsapp" && value["messages"]&.any?
  end

  def messenger_message?(change)
    change.key?("sender") && change.key?("message")
  end

  def process_whatsapp_message(change)
    value = change["value"]
    msg = value["messages"].first
    contact = value["contacts"]&.first

    conversation = find_or_create_conversation(
      platform: :whatsapp,
      external_contact_id: msg["from"],
      contact_name: contact&.dig("profile", "name")
    )

    message = create_message(
      conversation: conversation,
      external_message_id: msg["id"],
      content: extract_whatsapp_content(msg),
      message_type: map_whatsapp_type(msg["type"]),
      sent_at: Time.at(msg["timestamp"].to_i),
      metadata: msg.except("id", "from", "timestamp", "type", "text")
    )

    Result.new(conversation: conversation, message: message)
  end

  def process_messenger_message(change)
    sender_id = change.dig("sender", "id")
    recipient_id = change.dig("recipient", "id")
    msg = change["message"]
    return unless msg

    # Determine platform from top-level object field
    platform = instagram? ? :instagram : :facebook

    # Messages from our page are outbound (auto-replies)
    outbound = sender_id == page_id
    contact_id = outbound ? recipient_id : sender_id

    conversation = find_or_create_conversation(
      platform: platform,
      external_contact_id: contact_id,
      contact_name: outbound ? nil : fetch_ig_username(sender_id)
    )

    message = conversation.messages.create!(
      direction: outbound ? :outbound : :inbound,
      external_message_id: msg["mid"],
      content: msg["text"],
      message_type: detect_ig_message_type(msg),
      sent_at: Time.at(change["timestamp"].to_i / 1000.0),
      metadata: msg.except("mid", "text")
    )

    Result.new(conversation: conversation, message: message)
  end

  def find_or_create_conversation(platform:, external_contact_id:, contact_name:)
    conversation = Conversation.find_or_initialize_by(
      platform: platform,
      external_contact_id: external_contact_id
    )
    conversation.contact_name = contact_name if contact_name.present?
    conversation.status = :open
    conversation.save!
    conversation
  end

  def create_message(conversation:, external_message_id:, content:, message_type:, sent_at:, metadata:)
    conversation.messages.create!(
      direction: :inbound,
      external_message_id: external_message_id,
      content: content,
      message_type: message_type,
      sent_at: sent_at,
      metadata: metadata.presence || {}
    )
  end

  def extract_whatsapp_content(msg)
    case msg["type"]
    when "text" then msg.dig("text", "body")
    when "image" then msg.dig("image", "caption") || "[Image]"
    when "audio" then "[Audio]"
    when "video" then msg.dig("video", "caption") || "[Video]"
    when "document" then msg.dig("document", "filename") || "[Document]"
    when "sticker" then "[Sticker]"
    when "location" then "[Location: #{msg.dig("location", "latitude")}, #{msg.dig("location", "longitude")}]"
    when "reaction" then msg.dig("reaction", "emoji") || "[Reaction]"
    else "[#{msg["type"]}]"
    end
  end

  def detect_ig_message_type(msg)
    attachment_type = msg.dig("attachments", 0, "type")
    case attachment_type
    when "image" then :image
    when "video" then :video
    when "audio" then :audio
    when "file" then :document
    when "share", "story_mention" then :text
    when nil then :text
    else :text
    end
  end

  def fetch_ig_username(user_id)
    token = ENV["META_IG_ACCESS_TOKEN"].presence || ENV["META_ACCESS_TOKEN"]
    return nil if token.blank?

    response = Net::HTTP.get(
      URI("https://graph.instagram.com/v25.0/#{user_id}?fields=name,username&access_token=#{token}")
    )
    data = JSON.parse(response)
    data["name"] || data["username"]
  rescue StandardError => e
    Rails.logger.warn("[MetaWebhookService] Failed to fetch IG username for #{user_id}: #{e.message}")
    nil
  end

  def map_whatsapp_type(type)
    case type
    when "text" then :text
    when "image" then :image
    when "audio" then :audio
    when "video" then :video
    when "document" then :document
    when "sticker" then :sticker
    when "location" then :location
    when "reaction" then :reaction
    else :text
    end
  end
end
