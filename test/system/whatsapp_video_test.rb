require "application_system_test_case"
require_relative "../support/video_recording"

# Captures numbered screenshots for a video walkthrough of WhatsApp conversations.
# Assembled into a narrated MP4 by the e2e-video-doc plugin, which also discovers the
# devcontainer name rather than hardcoding it. See e2e-video-doc.json.
#
#   bash <plugin>/engine/run.sh whatsapp
class WhatsappVideoTest < ApplicationSystemTestCase
  include VideoRecording
  # 16:9 *viewport* to match the video frame, so the engine pads nothing: the window
  # is 143px taller than the shot because Selenium's chrome eats that much.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1280, 863 ] do |options|
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--force-device-scale-factor=1")
    # Keeps the "Enable desktop notifications" banner out of every frame: the view
    # only shows it while the permission is still "default".
    options.add_argument("--disable-notifications")
  end

  setup do
    # Before setup_video_recording: it rm -rf's the screenshot directory, so a
    # skip in the test body would still wipe the captures of the last real run.
    skip "only with RUN_VIDEO_TESTS=1" unless ENV["RUN_VIDEO_TESTS"]

    @consultant = create(:user, name: "Ana Mendez")
    @customer = create(:customer, company_name: "Kleer", responsible_consultant: @consultant)
    create(:contact, customer: @customer, name: "Juan Gabardini", email: "juan@kleer.la", primary: true)

    setup_video_recording
  end

  def scenario_name = "whatsapp"

  test "capture WhatsApp conversation screenshots for video" do
    sign_in_via_ui(@consultant)

    # ── SCENE 1: Empty inbox ──
    visit conversations_path
    capture("inbox_empty")

    # ── SCENE 2: First message arrives (simulate inbound) ──
    conversation = create_conversation("Carlos Pérez", "5491150373017")
    add_inbound(conversation, "Hola, estoy interesado en sus servicios de consultoría ágil", "wamid.video_001")

    visit conversations_path
    capture("first_message_arrives")

    # ── SCENE 3: Open the conversation ──
    click_on "Carlos Pérez"
    capture("conversation_opened")

    # ── SCENE 4: Consultant replies ──
    send_reply(conversation, "Hola Carlos! Gracias por contactarnos. ¿Qué tipo de consultoría necesitan?")
    visit conversation_path(conversation)
    capture("consultant_replies", scroll: :bottom)

    # ── SCENE 5: More messages from contact ──
    add_inbound(conversation, "Necesitamos coaching ágil para un equipo de 20 personas. Tenemos experiencia con Scrum pero queremos mejorar.", "wamid.video_002")
    visit conversation_path(conversation)
    capture("more_messages", scroll: :bottom)

    # ── SCENE 6: Document received ──
    add_inbound_document(conversation, "requisitos_proyecto.pdf", "wamid.video_003")
    visit conversation_path(conversation)
    capture("document_received", scroll: :bottom)

    # ── SCENE 7: Consultant replies to document ──
    send_reply(conversation, "Perfecto, revisamos el documento y les preparamos una propuesta.")
    visit conversation_path(conversation)
    capture("reply_to_document", scroll: :bottom)

    # ── SCENE 8: Add internal note ──
    add_note(conversation, "Buen fit para coaching enterprise. Hablar con Juan sobre pricing.")
    visit conversation_path(conversation)
    capture("internal_note", scroll: :bottom)

    # ── SCENE 9: Assign consultant ──
    select "Ana Mendez", from: "assigned_user_id"
    sleep 0.5
    capture("assigned_consultant")

    # ── SCENE 10: Link to customer ──
    visit conversation_path(conversation)
    select "Kleer", from: "linkable_combo" rescue nil
    sleep 0.5
    visit conversation_path(conversation.reload)
    capture("linked_to_customer")

    # ── SCENE 11: Final reply and close ──
    send_reply(conversation, "Perfecto Carlos, te enviamos la propuesta esta semana. ¡Saludos!")
    conversation.reload
    conversation.open! if conversation.closed?
    visit conversation_path(conversation)
    capture("final_reply", scroll: :bottom)

    # ── SCENE 12: Close conversation ──
    find("button", text: "Close").click
    sleep 0.5
    capture("conversation_closed")

    # ── SCENE 13: Closed filter in inbox ──
    visit conversations_path(status: "closed")
    capture("closed_filter")

    # ── Summary ──
    puts "\n#{@step} screenshots saved to #{screenshot_dir}"
  end

  private

  # Create messages directly in the DB (bypasses Turbo Stream broadcast issues in test)
  def create_conversation(name, phone)
    Conversation.create!(
      platform: :whatsapp,
      external_contact_id: phone,
      contact_name: name,
      status: :open,
      last_message_at: Time.current
    )
  end

  def add_inbound(conversation, content, message_id)
    conversation.messages.create!(
      direction: :inbound,
      content: content,
      message_type: :text,
      external_message_id: message_id,
      sent_at: Time.current
    )
  end

  def add_inbound_document(conversation, filename, message_id)
    conversation.messages.create!(
      direction: :inbound,
      content: filename,
      message_type: :document,
      external_message_id: message_id,
      sent_at: Time.current,
      metadata: { "document" => { "filename" => filename, "url" => "https://example.com/#{filename}" } }
    )
  end

  def send_reply(conversation, content)
    conversation.messages.create!(
      direction: :outbound,
      content: content,
      message_type: :text,
      sent_at: Time.current
    )
  end

  def add_note(conversation, content)
    conversation.messages.create!(
      direction: :outbound,
      content: content,
      message_type: :note,
      sent_at: Time.current
    )
  end
end
