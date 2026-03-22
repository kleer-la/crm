FactoryBot.define do
  factory :contact do
    sequence(:name) { |n| "Contact Person #{n}" }
    sequence(:email) { |n| "custcontact#{n}@customer.com" }
    phone { "555-0100" }
    role_title { "Manager" }
    primary { false }
    association :customer
  end
end
