class NullProvider
  def send_message(message)
    Rails.logger.info("[NullProvider] Would send message ##{message.id} (conversation ##{message.conversation_id})")
    MessageDispatcher::Result.new(success: true)
  end
end
