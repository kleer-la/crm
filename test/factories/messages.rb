FactoryBot.define do
  factory :message do
    association :conversation
    direction { :inbound }
    content { "Hello, I have a question about your services." }
    message_type { :text }
    sequence(:external_message_id) { |n| "wamid.#{n}" }
    sent_at { Time.current }
    metadata { {} }

    trait :outbound do
      direction { :outbound }
      content { "Thanks for reaching out! How can we help?" }
    end

    trait :image do
      message_type { :image }
      content { "[Image]" }
      metadata { { "image" => { "id" => "img_123" } } }
    end
  end
end
