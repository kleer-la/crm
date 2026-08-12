module TelegramFormatting
  PLATFORM_NAMES = { "whatsapp" => "WhatsApp", "instagram" => "Instagram", "facebook" => "Facebook" }.freeze

  private

  def platform_name(conversation)
    PLATFORM_NAMES.fetch(conversation.platform, conversation.platform)
  end

  def h(text)
    CGI.escapeHTML(text.to_s)
  end

  def conversation_link(conversation, label)
    url = Rails.application.routes.url_helpers.conversation_url(conversation)
    %(<a href="#{url}">#{h(label)}</a>)
  end
end
