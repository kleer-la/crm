require "test_helper"

class WhatsappConversationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @consultant = create(:user, name: "Ana Consultant")
    @customer = create(:customer, company_name: "Kleer", responsible_consultant: @consultant)
    ENV["META_APP_SECRET"] = "test_secret"
  end

  teardown do
    ENV.delete("META_APP_SECRET")
  end

  test "full WhatsApp conversation lifecycle: contact, respond, link to customer" do
    # =========================================================================
    # Step 1: A new contact sends a WhatsApp message (inbound via webhook)
    # =========================================================================
    webhook_payload = whatsapp_webhook(
      from: "5491150373017",
      name: "Carlos Perez",
      message_id: "wamid.initial_001",
      text: "Hola, estoy interesado en sus servicios de consultoría",
      timestamp: 5.minutes.ago
    )
    post "/webhooks/meta", params: webhook_payload.to_json,
         headers: webhook_headers(webhook_payload.to_json)
    assert_response :ok

    # Verify conversation and message were created
    conversation = Conversation.find_by!(external_contact_id: "5491150373017")
    assert_equal "whatsapp", conversation.platform
    assert_equal "Carlos Perez", conversation.contact_name
    assert conversation.open?
    assert_equal 1, conversation.messages.count
    first_message = conversation.messages.first
    assert first_message.inbound?
    assert_includes first_message.content, "interesado en sus servicios"

    # =========================================================================
    # Step 2: Consultant sees the conversation in the inbox
    # =========================================================================
    sign_in(@consultant)

    get conversations_path
    assert_response :success
    assert_includes response.body, "Carlos Perez"
    assert_includes response.body, "interesado en sus servicios"

    # Verify unread indicator is showing (bold name or unread count)
    assert_equal 1, conversation.unread_count_for(@consultant)

    # =========================================================================
    # Step 3: Consultant opens the conversation (marks as read)
    # =========================================================================
    get conversation_path(conversation)
    assert_response :success
    assert_includes response.body, "Carlos Perez"
    assert_includes response.body, "interesado en sus servicios"

    # Opening marks it as read
    assert_equal 0, conversation.unread_count_for(@consultant)

    # =========================================================================
    # Step 4: Consultant sends a reply
    # =========================================================================
    post conversation_messages_path(conversation), params: {
      message: { content: "Hola Carlos! Gracias por contactarnos. Qué tipo de consultoría necesitan?", message_type: "text" }
    }
    assert_response :ok

    reply = conversation.messages.order(sent_at: :desc).first
    assert reply.outbound?
    assert reply.text?
    assert_includes reply.content, "Gracias por contactarnos"
    assert_equal 2, conversation.messages.count

    # =========================================================================
    # Step 5: Contact sends a second message (inbound via service directly)
    # =========================================================================
    simulate_inbound_whatsapp(
      conversation: conversation,
      message_id: "wamid.followup_002",
      content: "Necesitamos coaching ágil para un equipo de 20 personas",
      timestamp: 3.minutes.ago
    )

    assert_equal 3, conversation.messages.reload.count
    # Consultant now has 1 unread (the new inbound message after their last read)
    assert_equal 1, conversation.unread_count_for(@consultant)

    # =========================================================================
    # Step 6: Contact sends a third message with a document
    # =========================================================================
    simulate_inbound_whatsapp(
      conversation: conversation,
      message_id: "wamid.doc_003",
      content: "requisitos_proyecto.pdf",
      message_type: :document,
      metadata: { "document" => { "filename" => "requisitos_proyecto.pdf", "mime_type" => "application/pdf", "id" => "doc_media_003" } },
      timestamp: 2.minutes.ago
    )

    assert_equal 4, conversation.messages.reload.count
    doc_message = conversation.messages.find_by(external_message_id: "wamid.doc_003")
    assert doc_message.document?
    assert_equal "requisitos_proyecto.pdf", doc_message.content

    # =========================================================================
    # Step 7: Consultant reopens the conversation, sees new messages
    # =========================================================================
    get conversation_path(conversation)
    assert_response :success
    assert_includes response.body, "coaching ágil"
    assert_includes response.body, "requisitos_proyecto.pdf"
    assert_includes response.body, "Document"

    # All read now
    assert_equal 0, conversation.unread_count_for(@consultant)

    # =========================================================================
    # Step 8: Consultant replies to the document
    # =========================================================================
    post conversation_messages_path(conversation), params: {
      message: { content: "Perfecto, revisamos el documento y les preparamos una propuesta.", message_type: "text" }
    }
    assert_response :ok
    assert_equal 5, conversation.messages.reload.count

    # =========================================================================
    # Step 9: Consultant adds an internal note
    # =========================================================================
    post conversation_messages_path(conversation), params: {
      message: { content: "Parece buen fit para coaching enterprise. Hablar con Juan sobre pricing.", message_type: "note" }
    }
    assert_response :ok

    note = conversation.messages.order(sent_at: :desc).first
    assert note.note?
    assert note.outbound?
    assert_includes note.content, "buen fit para coaching enterprise"
    assert_equal 6, conversation.messages.reload.count

    # =========================================================================
    # Step 10: Consultant assigns the conversation to themselves
    # =========================================================================
    patch assign_conversation_path(conversation), params: { assigned_user_id: @consultant.id }
    assert_redirected_to conversation_path(conversation)
    assert_equal @consultant, conversation.reload.assigned_user

    # =========================================================================
    # Step 11: Consultant links the conversation to the customer
    # =========================================================================
    patch link_conversation_path(conversation), params: {
      linkable_type: "Customer", linkable_id: @customer.id
    }
    assert_redirected_to conversation_path(conversation)
    assert_equal @customer, conversation.reload.linkable

    # Verify the show page displays the linked customer
    get conversation_path(conversation)
    assert_response :success
    assert_includes response.body, "Kleer"

    # =========================================================================
    # Step 12: Contact sends one more message, consultant closes the conversation
    # =========================================================================
    simulate_inbound_whatsapp(
      conversation: conversation,
      message_id: "wamid.thanks_004",
      content: "Genial, quedo a la espera. Gracias!",
      timestamp: 1.minute.ago
    )
    assert_equal 7, conversation.messages.reload.count

    # Consultant sends final reply and closes
    post conversation_messages_path(conversation), params: {
      message: { content: "Perfecto Carlos, te enviamos la propuesta esta semana. Saludos!", message_type: "text" }
    }
    assert_response :ok

    patch close_conversation_path(conversation)
    assert_redirected_to conversation_path(conversation)
    assert conversation.reload.closed?

    # =========================================================================
    # Step 13: Verify closed conversation appears correctly in inbox
    # =========================================================================
    # Default view (open) should NOT show the closed conversation
    get conversations_path
    assert_response :success
    assert_not_includes response.body, "Carlos Perez"

    # Closed filter should show it
    get conversations_path(status: "closed")
    assert_response :success
    assert_includes response.body, "Carlos Perez"
    assert_includes response.body, "Closed"

    # All filter shows it too
    get conversations_path(status: "all")
    assert_response :success
    assert_includes response.body, "Carlos Perez"

    # =========================================================================
    # Final assertions: full conversation integrity
    # =========================================================================
    conversation.reload
    assert_equal 8, conversation.messages.count
    assert_equal 4, conversation.messages.inbound.count   # 4 from contact
    assert_equal 4, conversation.messages.outbound.count   # 2 replies + 1 note + 1 final reply
    assert_equal 1, conversation.messages.where(message_type: :note).count
    assert_equal 1, conversation.messages.where(message_type: :document).count
    assert conversation.closed?
    assert_equal @consultant, conversation.assigned_user
    assert_equal @customer, conversation.linkable
  end

  private

  def whatsapp_webhook(from:, name:, message_id:, text:, timestamp:)
    {
      "object" => "whatsapp_business_account",
      "entry" => [ {
        "id" => "123456",
        "changes" => [ {
          "value" => {
            "messaging_product" => "whatsapp",
            "metadata" => { "display_phone_number" => "15551234567", "phone_number_id" => "test_phone_id" },
            "contacts" => [ { "profile" => { "name" => name }, "wa_id" => from } ],
            "messages" => [ {
              "id" => message_id,
              "from" => from,
              "timestamp" => timestamp.to_i.to_s,
              "type" => "text",
              "text" => { "body" => text }
            } ]
          },
          "field" => "messages"
        } ]
      } ]
    }
  end

  def whatsapp_webhook_document(from:, name:, message_id:, filename:, timestamp:)
    {
      "object" => "whatsapp_business_account",
      "entry" => [ {
        "id" => "123456",
        "changes" => [ {
          "value" => {
            "messaging_product" => "whatsapp",
            "metadata" => { "display_phone_number" => "15551234567", "phone_number_id" => "test_phone_id" },
            "contacts" => [ { "profile" => { "name" => name }, "wa_id" => from } ],
            "messages" => [ {
              "id" => message_id,
              "from" => from,
              "timestamp" => timestamp.to_i.to_s,
              "type" => "document",
              "document" => { "filename" => filename, "mime_type" => "application/pdf", "id" => "doc_media_#{message_id}" }
            } ]
          },
          "field" => "messages"
        } ]
      } ]
    }
  end

  def webhook_headers(body)
    signature = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", "test_secret", body)}"
    {
      "Content-Type" => "application/json",
      "X-Hub-Signature-256" => signature
    }
  end

  def simulate_inbound_whatsapp(conversation:, message_id:, content:, message_type: :text, metadata: {}, timestamp: Time.current)
    conversation.messages.create!(
      direction: :inbound,
      external_message_id: message_id,
      content: content,
      message_type: message_type,
      sent_at: timestamp,
      metadata: metadata
    )
  end
end
