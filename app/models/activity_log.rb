class ActivityLog < ApplicationRecord
  enum :entry_type, { system: 0, touchpoint: 1 }
  enum :touchpoint_type, { call: 0, email: 1, meeting: 2, note: 3 }

  belongs_to :loggable, polymorphic: true
  belongs_to :user

  validates :entry_type, presence: true
  validates :content, presence: true
  validates :touchpoint_type, presence: true, if: :touchpoint?

  def readonly?
    persisted?
  end
end
