class CannedResponse < ApplicationRecord
  AUTO_DISCONNECT_KEY = "auto_disconnect".freeze
  WELCOME_KEY = "welcome".freeze
  WELCOME_AFTER_HOURS_KEY = "welcome_after_hours".freeze

  validates :name, presence: true
  validates :content, presence: true
  validates :key, uniqueness: true, allow_nil: true

  scope :ordered, -> { order(:position, :name) }

  def system?
    key.present?
  end

  def self.auto_disconnect
    find_by(key: AUTO_DISCONNECT_KEY)
  end

  def self.welcome
    find_by(key: WELCOME_KEY)
  end

  def self.welcome_after_hours
    find_by(key: WELCOME_AFTER_HOURS_KEY)
  end
end
