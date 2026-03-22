FactoryBot.define do
  factory :proposal do
    sequence(:title) { |n| "Proposal #{n}" }
    status { :draft }
    association :responsible_consultant, factory: :user
    association :linkable, factory: :customer

    trait :sent do
      status { :sent }
      date_sent { Date.current }
      expected_close_date { 30.days.from_now.to_date }
    end

    trait :won do
      status { :won }
      win_loss_reason { "Best proposal" }
      final_value { 50000.00 }
      actual_close_date { Date.current }
    end

    trait :lost do
      status { :lost }
      win_loss_reason { "Price too high" }
      actual_close_date { Date.current }
    end
  end
end
