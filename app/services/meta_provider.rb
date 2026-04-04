class MetaProvider
  def send_message(message)
    # TODO: implement Meta WhatsApp/Instagram Send API
    Rails.logger.warn("[MetaProvider] Not yet implemented — message ##{message.id} not sent")
    MessageDispatcher::Result.new(success: false, error: "MetaProvider not yet implemented")
  end
end
