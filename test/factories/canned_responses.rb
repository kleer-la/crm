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
  end
end
