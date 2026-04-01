class Message < ApplicationRecord
  belongs_to :conversation, touch: true

  enum :direction, { inbound: 0, outbound: 1 }
  enum :message_type, { text: 0, image: 1, audio: 2, video: 3, document: 4, sticker: 5, location: 6, reaction: 7 }

  validates :direction, presence: true
  validates :sent_at, presence: true
  validates :content, presence: true, if: -> { text? }

  after_create :update_conversation_last_message_at

  private

  def update_conversation_last_message_at
    conversation.update_column(:last_message_at, sent_at) if sent_at > (conversation.last_message_at || Time.at(0))
  end
end
