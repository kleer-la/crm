FactoryBot.define do
  factory :conversation do
    platform { :whatsapp }
    sequence(:external_contact_id) { |n| "5491155500#{n.to_s.rjust(3, '0')}" }
    contact_name { "Test Contact" }
    status { :open }
    last_message_at { Time.current }

    trait :instagram do
      platform { :instagram }
      sequence(:external_contact_id) { |n| "ig_user_#{n}" }
    end

    trait :facebook do
      platform { :facebook }
      sequence(:external_contact_id) { |n| "fb_user_#{n}" }
    end

    trait :closed do
      status { :closed }
    end

    trait :with_messages do
      after(:create) do |conversation|
        create(:message, conversation: conversation, direction: :inbound, sent_at: 2.hours.ago)
        create(:message, conversation: conversation, direction: :outbound, sent_at: 1.hour.ago)
      end
    end
  end
end
