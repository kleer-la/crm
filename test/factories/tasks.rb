FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Task #{n}" }
    due_date { 3.days.from_now.to_date }
    priority { :medium }
    status { :open }
    association :assigned_to, factory: :user
    association :linkable, factory: :customer

    trait :overdue do
      due_date { 5.days.ago.to_date }

      to_create do |instance|
        instance.save!(validate: false)
      end
    end

    trait :done do
      status { :done }
      completed_at { Time.current }
    end

    trait :cancelled do
      status { :cancelled }
      cancellation_reason { "No longer needed" }
    end
  end
end
