class WelcomeMessageJob < ApplicationJob
  queue_as :default

  BUSINESS_TIMEZONE = "America/Argentina/Buenos_Aires".freeze
  BUSINESS_DAYS = (1..5) # Monday to Friday
  BUSINESS_HOURS = (9...18) # 09:00 to 17:59

  def perform(conversation)
    canned = welcome_response
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

  private

  def welcome_response
    if business_hours?
      CannedResponse.welcome
    else
      CannedResponse.welcome_after_hours || CannedResponse.welcome
    end
  end

  def business_hours?
    now = Time.current.in_time_zone(BUSINESS_TIMEZONE)
    BUSINESS_DAYS.cover?(now.wday) && BUSINESS_HOURS.cover?(now.hour)
  end
end
