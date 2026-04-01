class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy

  enum :platform, { whatsapp: 0, instagram: 1, facebook: 2 }
  enum :status, { open: 0, closed: 1 }

  validates :platform, presence: true
  validates :external_contact_id, presence: true, uniqueness: { scope: :platform }
  validates :status, presence: true

  scope :recent, -> { order(last_message_at: :desc) }

  def display_name
    contact_name.presence || external_contact_id
  end

  def platform_label
    case platform
    when "whatsapp" then "WA"
    when "instagram" then "IG"
    when "facebook" then "FB"
    end
  end
end
