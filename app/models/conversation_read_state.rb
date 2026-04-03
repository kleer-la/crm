class ConversationReadState < ApplicationRecord
  belongs_to :user
  belongs_to :conversation

  validates :user_id, uniqueness: { scope: :conversation_id }
  validates :last_read_at, presence: true
end
