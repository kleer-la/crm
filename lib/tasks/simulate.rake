namespace :simulate do
  desc "Simulate inbound WhatsApp webhook messages. Usage: rake simulate:webhook[5]"
  task :webhook, [:count] => :environment do |_t, args|
    count = (args[:count] || 5).to_i

    contacts = [
      { name: "Carlos Martinez", phone: "5491155501001" },
      { name: "Ana Lopez", phone: "5491155501002" },
      { name: "Diego Fernandez", phone: "5491155501003" },
      { name: "Laura Gomez", phone: "5491155501004" }
    ]

    message_templates = [
      { type: :text, content: "Hola, quisiera saber sobre sus servicios de consultoría" },
      { type: :text, content: "Tenemos un proyecto de transformación ágil para Q3" },
      { type: :text, content: "Pueden enviarnos una propuesta?" },
      { type: :text, content: "Cuánto cuesta un workshop de 2 días?" },
      { type: :text, content: "Perfecto, coordinamos una llamada esta semana?" },
      { type: :image, content: "[Image]", metadata: { "image" => { "url" => "https://placehold.co/400x300", "id" => "img_sim_#{SecureRandom.hex(4)}" } } },
      { type: :audio, content: "[Audio]", metadata: { "audio" => { "url" => "https://example.com/audio.ogg", "id" => "aud_sim_#{SecureRandom.hex(4)}" } } },
      { type: :document, content: "[Document]", metadata: { "document" => { "url" => "https://example.com/brief.pdf", "filename" => "project_brief.pdf", "id" => "doc_sim_#{SecureRandom.hex(4)}" } } }
    ]

    count.times do |i|
      contact = contacts.sample
      template = message_templates.sample

      conversation = Conversation.find_or_create_by!(
        platform: :whatsapp,
        external_contact_id: contact[:phone]
      ) do |c|
        c.contact_name = contact[:name]
        c.status = :open
        c.last_message_at = Time.current
      end

      conversation.update!(contact_name: contact[:name]) if conversation.contact_name != contact[:name]

      message = conversation.messages.create!(
        direction: :inbound,
        message_type: template[:type],
        content: template[:content],
        external_message_id: "sim_#{SecureRandom.hex(8)}",
        sent_at: Time.current - (count - i).minutes,
        metadata: template[:metadata] || {}
      )

      puts "  [#{i + 1}/#{count}] #{contact[:name]} (#{contact[:phone]}): #{template[:content].truncate(50)}"
    end

    puts "\nDone! Created #{count} simulated messages across #{Conversation.where(external_contact_id: contacts.pluck(:phone)).count} conversations."
  end
end
