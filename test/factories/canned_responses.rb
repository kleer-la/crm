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
  end
end
