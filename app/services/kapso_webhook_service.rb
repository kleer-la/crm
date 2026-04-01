class KapsoWebhookService
  Result = Struct.new(:conversation, :message, keyword_init: true)

  def self.process(data)
    new(data).process
  end

  def initialize(data)
    @data = data
  end

  def process
    msg = @data["message"]
    conv = @data["conversation"]
    return [] unless msg && conv

    conversation = find_or_create_conversation(conv)
    message = create_message(conversation, msg)

    [ Result.new(conversation: conversation, message: message) ]
  end

  private

  def find_or_create_conversation(conv)
    phone = conv["phone_number"]
    contact_name = conv.dig("kapso", "contact_name")

    conversation = Conversation.find_or_initialize_by(
      platform: :whatsapp,
      external_contact_id: phone
    )
    conversation.contact_name = contact_name if contact_name.present?
    conversation.status = :open
    conversation.save!
    conversation
  end

  def create_message(conversation, msg)
    kapso = msg["kapso"] || {}

    conversation.messages.create!(
      direction: kapso["direction"] == "outbound" ? :outbound : :inbound,
      external_message_id: msg["id"],
      content: extract_content(msg),
      message_type: map_type(msg["type"]),
      sent_at: Time.at(msg["timestamp"].to_i),
      metadata: kapso.except("direction", "status", "content")
    )
  end

  def extract_content(msg)
    case msg["type"]
    when "text" then msg.dig("text", "body")
    when "image" then msg.dig("image", "caption") || "[Image]"
    when "audio" then "[Audio]"
    when "video" then msg.dig("video", "caption") || "[Video]"
    when "document" then msg.dig("document", "filename") || "[Document]"
    when "sticker" then "[Sticker]"
    when "location" then "[Location]"
    when "reaction" then msg.dig("reaction", "emoji") || "[Reaction]"
    else "[#{msg["type"]}]"
    end
  end

  def map_type(type)
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
