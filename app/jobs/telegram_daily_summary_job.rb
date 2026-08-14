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

    waiting_ids = awaiting_reply(open_conversations).pluck(:id).to_set

    grouped_by_assignee(open_conversations, waiting_ids).each do |assignee, conversations|
      waiting = conversations.select { |c| waiting_ids.include?(c.id) }.sort_by(&:last_message_at)

      lines << ""
      lines << "<b>#{assignee ? h(assignee.name) : "Sin asignar"}</b> — #{count_label(conversations.size, "abierta")}, #{count_label(waiting.size, "espera")} respuesta#{":" if waiting.any?}"
      waiting.each do |conversation|
        lines << "  ⏳ #{conversation_link(conversation, conversation.display_name)} (#{platform_name(conversation)}) — #{waiting_label(conversation)}"
      end
    end

    lines.join("\n")
  end

  # Unassigned bucket first, then assignees with the most conversations awaiting a reply
  def grouped_by_assignee(open_conversations, waiting_ids)
    open_conversations.includes(:assigned_user).group_by(&:assigned_user).sort_by do |assignee, conversations|
      [ assignee.nil? ? 0 : 1, -conversations.count { |c| waiting_ids.include?(c.id) } ]
    end
  end

  def count_label(count, noun)
    case noun
    when "abierta" then "#{count} #{count == 1 ? "abierta" : "abiertas"}"
    when "espera" then "#{count} #{count == 1 ? "espera" : "esperan"}"
    end
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
