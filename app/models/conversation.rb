class Conversation < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_by_contact, against: :contact_name, using: { trigram: { threshold: 0.3 } }

  has_many :messages, dependent: :destroy
  has_many :read_states, class_name: "ConversationReadState", dependent: :destroy
  belongs_to :assigned_user, class_name: "User", optional: true
  belongs_to :linkable, polymorphic: true, optional: true

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

  def unread_count_for(user)
    read_state = read_states.find_by(user: user)
    if read_state
      messages.where("sent_at > ?", read_state.last_read_at).count
    else
      messages.count
    end
  end

  def mark_as_read!(user)
    read_states.find_or_initialize_by(user: user).tap do |rs|
      rs.last_read_at = Time.current
      rs.save!
    end
  end
end
