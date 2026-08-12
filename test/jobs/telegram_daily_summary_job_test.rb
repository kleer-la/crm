require "test_helper"

class TelegramDailySummaryJobTest < ActiveSupport::TestCase
  setup do
    @notifications = []
    captured = @notifications
    TelegramNotifier.singleton_class.alias_method(:original_notify, :notify)
    TelegramNotifier.define_singleton_method(:notify) { |text| captured << text; true }
  end

  teardown do
    TelegramNotifier.singleton_class.alias_method(:notify, :original_notify)
    TelegramNotifier.singleton_class.remove_method(:original_notify)
  end

  test "does not notify when there are no open conversations" do
    create(:conversation, :closed)

    TelegramDailySummaryJob.perform_now

    assert_empty @notifications
  end

  test "summarizes open conversations by platform and lists those awaiting reply" do
    waiting = create(:conversation, platform: :whatsapp, contact_name: "Juan", last_message_at: nil)
    create(:message, conversation: waiting, direction: :inbound, sent_at: 3.hours.ago)

    answered = create(:conversation, :instagram, contact_name: "Ana")
    create(:message, conversation: answered, direction: :inbound, sent_at: 2.hours.ago)
    create(:message, :outbound, conversation: answered, sent_at: 1.hour.ago)

    create(:conversation, :closed, platform: :whatsapp)

    TelegramDailySummaryJob.perform_now

    text = @notifications.last
    assert_includes text, "Conversaciones abiertas: 2"
    assert_includes text, "WhatsApp: 1"
    assert_includes text, "Instagram: 1"
    assert_includes text, "Juan"
    assert_includes text, "hace 3 h"
    assert_includes text, "/conversations/#{waiting.id}"
    assert_not_includes text, "Ana"
  end

  test "says so when no open conversation awaits a reply" do
    answered = create(:conversation, contact_name: "Ana")
    create(:message, conversation: answered, direction: :inbound, sent_at: 2.hours.ago)
    create(:message, :outbound, conversation: answered, sent_at: 1.hour.ago)

    TelegramDailySummaryJob.perform_now

    text = @notifications.last
    assert_includes text, "Conversaciones abiertas: 1"
    assert_includes text, "Ninguna espera respuesta"
  end
end
