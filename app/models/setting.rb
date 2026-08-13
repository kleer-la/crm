class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.get(key)
    find_by(key: key)&.value
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.update!(value: value)
    value
  end

  # The Instagram token is refreshed periodically (RefreshIgTokenJob) and each
  # refresh yields a new string, so the database value wins over the ENV seed.
  def self.ig_access_token
    get("ig_access_token").presence || ENV["META_IG_ACCESS_TOKEN"]
  end

  # Off by default: must stay off while Instagram's native auto-reply is active
  # in Meta Business Suite, or new contacts get greeted twice.
  def self.ig_welcome_enabled?
    get("ig_welcome_enabled") == "true"
  end
end
