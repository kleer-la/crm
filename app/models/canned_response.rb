class CannedResponse < ApplicationRecord
  AUTO_DISCONNECT_KEY = "auto_disconnect".freeze

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
end
