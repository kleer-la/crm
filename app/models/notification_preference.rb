class NotificationPreference < ApplicationRecord
  TYPES = %w[task_due_reminder proposal_status_change].freeze

  belongs_to :user

  validates :notification_type, presence: true, inclusion: { in: TYPES }
  validates :notification_type, uniqueness: { scope: :user_id }
end
