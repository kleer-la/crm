class NullProvider
  def send_message(message)
    Rails.logger.info("[NullProvider] Would send message ##{message.id} to #{message.conversation.external_contact_id}: #{message.content}")
    MessageDispatcher::Result.new(success: true)
  end
end
