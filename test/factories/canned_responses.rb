FactoryBot.define do
  factory :canned_response do
    sequence(:name) { |n| "Quick reply #{n}" }
    content { "Hello, thanks for reaching out!" }
    position { 0 }

    trait :auto_disconnect do
      name { "Desconexión automática" }
      content { "Nos desconectamos de esta conversación, avisanos si querés continuar" }
      key { CannedResponse::AUTO_DISCONNECT_KEY }
    end

    trait :welcome do
      name { "Bienvenida" }
      content { "¡Hola! Gracias por contactarnos, en breve te respondemos." }
      key { CannedResponse::WELCOME_KEY }
    end

    trait :welcome_after_hours do
      name { "Bienvenida fuera de horario" }
      content { "Gracias por contactarnos. Te atendemos de Lunes a Viernes de 9:00 a 18:00 (GMT-3)." }
      key { CannedResponse::WELCOME_AFTER_HOURS_KEY }
    end
  end
end
