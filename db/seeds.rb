# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Canned responses
CannedResponse.find_or_create_by!(key: CannedResponse::AUTO_DISCONNECT_KEY) do |cr|
  cr.name = "Desconexión automática"
  cr.content = "Nos desconectamos de esta conversación, avisanos si querés continuar"
  cr.position = 0
end

# Sample conversations for development
if Rails.env.development?
  user = User.first

  [
    { contact_name: "María López", platform: :whatsapp, external_contact_id: "5491155001234",
      messages: [
        { direction: :inbound, content: "Hola, quería consultar por el servicio de consultoría" },
        { direction: :outbound, content: "¡Hola María! Claro, contame qué necesitás" },
        { direction: :inbound, content: "Necesitamos mejorar nuestros procesos ágiles" }
      ] },
    { contact_name: "Juan Pérez", platform: :whatsapp, external_contact_id: "5491167005678",
      messages: [
        { direction: :inbound, content: "Buenas tardes, los contacto por una capacitación" },
        { direction: :outbound, content: "Hola Juan, ¿qué tipo de capacitación te interesa?" }
      ] },
    { contact_name: "Carolina Ruiz", platform: :instagram, external_contact_id: "ig_carolina_ruiz",
      messages: [
        { direction: :inbound, content: "Vi su publicación sobre coaching, me interesa saber más" },
        { direction: :outbound, content: "¡Hola Carolina! Te cuento cómo trabajamos" },
        { direction: :inbound, content: "Genial, ¿tienen disponibilidad para mayo?" },
        { direction: :inbound, content: "También me interesaría para mi equipo" }
      ] }
  ].each do |conv_data|
    messages_data = conv_data.delete(:messages)
    conversation = Conversation.find_or_create_by!(
      platform: conv_data[:platform],
      external_contact_id: conv_data[:external_contact_id]
    ) do |c|
      c.contact_name = conv_data[:contact_name]
      c.status = :open
      c.assigned_user = user
      c.last_message_at = Time.current
    end

    if conversation.messages.empty?
      messages_data.each_with_index do |msg, i|
        conversation.messages.create!(
          direction: msg[:direction],
          message_type: :text,
          content: msg[:content],
          sent_at: (messages_data.size - i).minutes.ago
        )
      end
    end
  end
end
