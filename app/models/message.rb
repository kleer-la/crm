class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  has_one_attached :file

  enum :direction, { inbound: 0, outbound: 1 }
  enum :message_type, { text: 0, image: 1, audio: 2, video: 3, document: 4, sticker: 5, location: 6, reaction: 7, note: 8 }

  validates :direction, presence: true
  validates :sent_at, presence: true
  validates :content, presence: true, if: -> { text? || note? }

  after_create :update_conversation_last_message_at
  after_create_commit :broadcast_message

  private

  def update_conversation_last_message_at
    conversation.update_column(:last_message_at, sent_at) if sent_at > (conversation.last_message_at || Time.at(0))
  end

  def broadcast_message
    broadcast_append_to(
      conversation,
      target: "messages",
      partial: "conversations/message",
      locals: { message: self }
    )
    broadcast_replace_to(
      "conversations",
      target: "conversation_#{conversation_id}",
      partial: "conversations/conversation_row",
      locals: { conversation: conversation.reload }
    )
  end
end
