FactoryBot.define do
  factory :deployment do
    sequence(:version) { |n| "abc#{n}def" }
    sequence(:commit_sha) { |n| "abc#{n}def1234567890abcdef1234567890abcdef12" }
    commit_url { "https://github.com/kleer-la/crm/commit/#{commit_sha}" }
    sequence(:commit_message) { |n| "Fix issue ##{n}" }
    sequence(:author) { |n| "Dev #{n} <dev#{n}@example.com>" }
    branch { "main" }
    environment { "production" }
    sequence(:deployed_at) { |n| n.hours.ago }
    deployed_by { "deployer" }

    trait :qa do
      environment { "qa" }
    end
  end
end
