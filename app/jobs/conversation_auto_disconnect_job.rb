class ConversationAutoDisconnectJob < ApplicationJob
  queue_as :default

  TIMEOUT_HOURS = ENV.fetch("AUTO_DISCONNECT_HOURS", 12).to_i

  def perform
    canned = CannedResponse.auto_disconnect
    unless canned
      Rails.logger.warn("[AutoDisconnect] No canned response with key '#{CannedResponse::AUTO_DISCONNECT_KEY}' found, skipping.")
      return
    end

    idle_conversations.find_each do |conversation|
      send_disconnect_message(conversation, canned.content)
      conversation.closed!
      Rails.logger.info("[AutoDisconnect] Closed conversation ##{conversation.id} (#{conversation.display_name})")
    end
  end

  private

  def idle_conversations
    cutoff = TIMEOUT_HOURS.hours.ago

    # Open conversations where last_message_at is older than cutoff
    # and the most recent message is outbound (we replied, they didn't)
    Conversation
      .where(status: :open)
      .where("last_message_at < ?", cutoff)
      .where(<<~SQL, direction: Message.directions[:outbound])
        (SELECT m.direction FROM messages m
         WHERE m.conversation_id = conversations.id
         ORDER BY m.sent_at DESC LIMIT 1) = :direction
      SQL
  end

  def send_disconnect_message(conversation, content)
    message = conversation.messages.create!(
      direction: :outbound,
      content: content,
      message_type: :text,
      sent_at: Time.current
    )
    MessageDispatcher.new.dispatch(message)
  end
end
