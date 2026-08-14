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

  test "groups open conversations by assignee with unassigned first" do
    vero = create(:user, name: "Vero")
    caro = create(:user, name: "Caro")

    assigned_waiting = create(:conversation, platform: :whatsapp, contact_name: "Pablo", assigned_user: vero, last_message_at: nil)
    create(:message, conversation: assigned_waiting, direction: :inbound, sent_at: 3.hours.ago)

    answered = create(:conversation, :instagram, contact_name: "Ana", assigned_user: caro)
    create(:message, conversation: answered, direction: :inbound, sent_at: 2.hours.ago)
    create(:message, :outbound, conversation: answered, sent_at: 1.hour.ago)

    unassigned_waiting = create(:conversation, platform: :whatsapp, contact_name: "María", last_message_at: nil)
    create(:message, conversation: unassigned_waiting, direction: :inbound, sent_at: 5.hours.ago)

    TelegramDailySummaryJob.perform_now

    text = @notifications.last
    assert_includes text, "Conversaciones abiertas: 3"
    assert_includes text, "WhatsApp: 2"
    assert_includes text, "Instagram: 1"

    assert_includes text, "<b>Sin asignar</b> — 1 abierta, 1 espera respuesta:"
    assert_includes text, "<b>Vero</b> — 1 abierta, 1 espera respuesta:"
    assert_includes text, "<b>Caro</b> — 1 abierta, 0 esperan respuesta"

    assert_operator text.index("Sin asignar"), :<, text.index("Vero")

    assert_includes text, "María"
    assert_includes text, "hace 5 h"
    assert_includes text, "/conversations/#{unassigned_waiting.id}"
    assert_includes text, "Pablo"
    assert_includes text, "hace 3 h"
    assert_not_includes text, "Ana"
  end

  test "orders assignees by most conversations awaiting reply" do
    quiet = create(:user, name: "Quiet Consultant")
    busy = create(:user, name: "Busy Consultant")

    create(:conversation, contact_name: "Answered", assigned_user: quiet, last_message_at: nil).then do |c|
      create(:message, conversation: c, direction: :inbound, sent_at: 3.hours.ago)
      create(:message, :outbound, conversation: c, sent_at: 1.hour.ago)
    end

    create(:conversation, contact_name: "Waiting", assigned_user: busy, last_message_at: nil).then do |c|
      create(:message, conversation: c, direction: :inbound, sent_at: 2.hours.ago)
    end

    TelegramDailySummaryJob.perform_now

    text = @notifications.last
    assert_operator text.index("Busy Consultant"), :<, text.index("Quiet Consultant")
  end

  test "omits consultants without open conversations" do
    create(:user, name: "Idle Consultant")
    open_conv = create(:conversation, contact_name: "Ana")
    create(:message, conversation: open_conv, direction: :inbound, sent_at: 1.hour.ago)

    TelegramDailySummaryJob.perform_now

    assert_not_includes @notifications.last, "Idle Consultant"
  end
end
