class TelegramDailySummaryJob < ApplicationJob
  include TelegramFormatting

  queue_as :default

  def perform
    open_conversations = Conversation.where(status: :open)
    if open_conversations.none?
      Rails.logger.info("[TelegramDailySummary] No open conversations, skipping.")
      return
    end

    TelegramNotifier.notify(summary_text(open_conversations))
  end

  private

  def summary_text(open_conversations)
    counts = open_conversations.group(:platform).count
    by_platform = counts.map { |platform, count| "#{PLATFORM_NAMES.fetch(platform, platform)}: #{count}" }.join(", ")

    lines = [ "📋 <b>Conversaciones abiertas: #{open_conversations.count}</b> (#{by_platform})" ]

    waiting = awaiting_reply(open_conversations).order(last_message_at: :asc)
    if waiting.any?
      lines << ""
      lines << "⏳ Esperando respuesta:"
      waiting.each do |conversation|
        lines << "• #{conversation_link(conversation, conversation.display_name)} (#{platform_name(conversation)}) — #{waiting_label(conversation)}"
      end
    else
      lines << "✅ Ninguna espera respuesta."
    end

    lines.join("\n")
  end

  # Open conversations whose most recent message is inbound (they wrote, we didn't reply)
  def awaiting_reply(scope)
    scope.where(<<~SQL, direction: Message.directions[:inbound])
      (SELECT m.direction FROM messages m
       WHERE m.conversation_id = conversations.id
       ORDER BY m.sent_at DESC LIMIT 1) = :direction
    SQL
  end

  def waiting_label(conversation)
    hours = ((Time.current - conversation.last_message_at) / 1.hour).round
    hours < 1 ? "hace menos de 1 h" : "hace #{hours} h"
  end
end
