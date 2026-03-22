FactoryBot.define do
  factory :customer do
    sequence(:company_name) { |n| "Customer Co #{n}" }
    status { :active }
    association :responsible_consultant, factory: :user
    date_became_customer { Date.current }
    last_activity_date { Date.current }
    total_revenue { 0 }

    trait :with_contact do
      after(:create) do |customer|
        create(:contact, customer: customer, primary: true)
      end
    end

    trait :inactive do
      status { :inactive }
    end
  end
end
