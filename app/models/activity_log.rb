class ActivityLog < ApplicationRecord
  enum :entry_type, { system: 0, touchpoint: 1 }
  enum :touchpoint_type, { call: 0, email: 1, meeting: 2, other: 3, chat: 4 }

  belongs_to :loggable, polymorphic: true
  belongs_to :user, optional: true

  validates :entry_type, presence: true
  validates :content, presence: true
  validates :touchpoint_type, presence: true, if: :touchpoint?
  validates :occurred_at, presence: true

  before_validation :set_occurred_at_default

  after_create_commit :update_parent_last_activity_date

  before_update { raise ActiveRecord::ReadOnlyRecord, "ActivityLog records are immutable" }
  before_destroy { throw :abort unless destroyed_by_association }

  def readonly?
    false
  end

  private

  def set_occurred_at_default
    self.occurred_at ||= Time.current
  end

  def update_parent_last_activity_date
    return unless loggable.respond_to?(:last_activity_date)

    if loggable.is_a?(Proposal)
      return unless touchpoint?
      loggable.update_column(:last_activity_date, occurred_at.to_date)
    else
      loggable.update_column(:last_activity_date, Time.current)
    end
  end
end
