FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:google_uid) { |n| "google_uid_#{n}" }
    role { :consultant }
    active { true }

    trait :admin do
      role { :admin }
    end

    trait :pending do
      role { :pending }
    end

    trait :deactivated do
      active { false }
    end
  end
end
