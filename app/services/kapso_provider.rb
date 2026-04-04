class KapsoProvider
  def send_message(message)
    # TODO: implement Kapso Send API
    Rails.logger.warn("[KapsoProvider] Not yet implemented — message ##{message.id} not sent")
    MessageDispatcher::Result.new(success: false, error: "KapsoProvider not yet implemented")
  end
end
