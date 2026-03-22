FactoryBot.define do
  factory :notification_preference do
    association :user
    notification_type { "task_due_reminder" }
    enabled { true }
  end
end
