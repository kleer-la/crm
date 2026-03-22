FactoryBot.define do
  factory :prospect do
    sequence(:company_name) { |n| "Prospect Co #{n}" }
    sequence(:primary_contact_name) { |n| "Contact #{n}" }
    sequence(:primary_contact_email) { |n| "contact#{n}@prospect.com" }
    status { :new_prospect }
    association :responsible_consultant, factory: :user
    date_added { Date.current }
    last_activity_date { Date.current }

    trait :qualified do
      status { :qualified }
    end

    trait :disqualified do
      status { :disqualified }
      disqualification_reason { "Budget too small" }
    end

    trait :converted do
      status { :converted }
      association :converted_customer, factory: :customer
    end
  end
end
