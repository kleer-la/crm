class WelcomeMessageJob < ApplicationJob
  queue_as :default

  def perform(conversation)
    canned = CannedResponse.welcome
    unless canned
      Rails.logger.warn("[WelcomeMessage] No canned response with key '#{CannedResponse::WELCOME_KEY}' found, skipping.")
      return
    end

    # A conversation that already got any outbound message (a consultant reply,
    # a previous welcome, an account-level auto-reply echo) must not be greeted.
    return if conversation.messages.outbound.exists?

    message = conversation.messages.create!(
      direction: :outbound,
      content: canned.content,
      message_type: :text,
      sent_at: Time.current
    )
    MessageDispatcher.new.dispatch(message)
    Rails.logger.info("[WelcomeMessage] Sent welcome to conversation ##{conversation.id} (#{conversation.display_name})")
  end
end
