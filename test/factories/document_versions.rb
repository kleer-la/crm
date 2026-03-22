FactoryBot.define do
  factory :document_version do
    sequence(:label) { |n| "Version #{n}" }
    url { "https://docs.google.com/doc/123" }
    association :proposal
    archived_at { Time.current }
    association :archived_by, factory: :user
  end
end
