FactoryBot.define do
  factory :conversation_read_state do
    association :user
    association :conversation
    last_read_at { Time.current }
  end
end
