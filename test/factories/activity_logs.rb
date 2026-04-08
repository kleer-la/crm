FactoryBot.define do
  factory :activity_log do
    entry_type { :system }
    content { "Something happened" }
    occurred_at { Time.current }
    association :loggable, factory: :prospect
    association :user

    trait :touchpoint do
      entry_type { :touchpoint }
      touchpoint_type { :call }
      content { "Called the client" }
    end
  end
end
