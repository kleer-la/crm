class TelegramNewConversationJob < ApplicationJob
  include TelegramFormatting

  queue_as :default

  def perform(conversation)
    first_message = conversation.messages.inbound.order(:sent_at).first

    lines = [ "🆕 Nueva conversación de <b>#{platform_name(conversation)}</b>" ]
    lines << "De: #{h(conversation.display_name)}"
    lines << "“#{h(first_message.content.truncate(200))}”" if first_message&.content.present?
    lines << conversation_link(conversation, "Abrir en el CRM")

    TelegramNotifier.notify(lines.join("\n"))
  end
end
