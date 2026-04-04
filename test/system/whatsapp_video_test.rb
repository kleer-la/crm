require "application_system_test_case"

# Captures numbered screenshots for a video walkthrough of WhatsApp conversations.
# Run with: docker exec -w /app crm_devcontainer-web-1 bin/rails test test/system/whatsapp_video_test.rb
#
# Screenshots are saved to tmp/video_screenshots/ with sequential numbering.
# Use scripts/make_video.sh to assemble into a narrated video.
class WhatsappVideoTest < ApplicationSystemTestCase
  # Tablet viewport for good visuals in video
  driven_by :selenium, using: :headless_chrome, screen_size: [1024, 768] do |options|
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--force-device-scale-factor=1")
  end

  setup do
    @consultant = create(:user, name: "Ana Mendez")
    @customer = create(:customer, company_name: "Kleer", responsible_consultant: @consultant)
    create(:contact, customer: @customer, name: "Juan Gabardini", email: "juan@kleer.la", primary: true)

    @screenshot_dir = Rails.root.join("tmp", "video_screenshots")
    FileUtils.rm_rf(@screenshot_dir)
    FileUtils.mkdir_p(@screenshot_dir)
    @step = 0
  end

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
    puts "\n#{@step} screenshots saved to tmp/video_screenshots/"
    puts "Run: bash scripts/make_video.sh"
  end

  private

  def capture(name, pause: 0.5, scroll: nil)
    case scroll
    when :bottom
      page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    when :top
      page.execute_script("window.scrollTo(0, 0)")
    when /\Atext:(.+)\z/
      text = $1
      element = find(:xpath, "//*[contains(text(), '#{text}')]", match: :first, visible: :all)
      scroll_to(element, align: :top)
    when /\Acss:(.+)\z/
      selector = $1
      element = find(selector, match: :first, visible: :all)
      scroll_to(element, align: :top)
    end

    sleep pause
    @step += 1
    filename = format("%02d_%s.png", @step, name)
    page.save_screenshot(@screenshot_dir.join(filename))
  end

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
