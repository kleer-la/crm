class ActivityLog < ApplicationRecord
  enum :entry_type, { system: 0, touchpoint: 1 }
  enum :touchpoint_type, { call: 0, email: 1, meeting: 2, note: 3 }

  belongs_to :loggable, polymorphic: true
  belongs_to :user, optional: true

  validates :entry_type, presence: true
  validates :content, presence: true
  validates :touchpoint_type, presence: true, if: :touchpoint?

  after_create_commit :update_parent_last_activity_date

  before_update { raise ActiveRecord::ReadOnlyRecord, "ActivityLog records are immutable" }

  def readonly?
    false
  end

  private

  def update_parent_last_activity_date
    return unless loggable.respond_to?(:last_activity_date)

    loggable.update_column(:last_activity_date, Time.current)
  end
end
