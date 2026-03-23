class Task < ApplicationRecord
  include Loggable

  enum :priority, { low: 0, medium: 1, high: 2 }
  enum :status, { open: 0, in_progress: 1, done: 2, cancelled: 3 }

  belongs_to :linkable, polymorphic: true
  belongs_to :assigned_to, class_name: "User"

  validates :title, presence: true
  validates :due_date, presence: true
  validates :priority, presence: true
  validates :status, presence: true
  validates :cancellation_reason, presence: true, if: :cancelled?
  validate :due_date_not_in_past, on: :create

  scope :overdue, -> { where(status: [ :open, :in_progress ]).where("due_date < ?", Date.current) }

  before_validation :set_completed_at, if: :done?

  after_commit :log_creation, on: :create
  after_commit :log_changes, on: :update

  def mark_done!
    update!(status: :done)
  end

  def cancel!(reason)
    update!(status: :cancelled, cancellation_reason: reason)
  end

  private

  def due_date_not_in_past
    if due_date.present? && due_date < Date.current
      errors.add(:due_date, "cannot be in the past")
    end
  end

  def set_completed_at
    self.completed_at ||= Time.current if status_changed?
  end

  def log_creation
    log_system_event("Task created: #{title}")
    linkable.log_system_event("Task added: #{title}") if linkable.respond_to?(:log_system_event)
  end

  def log_changes
    log_status_change if previous_changes.key?("status")
    log_assignment_change if previous_changes.key?("assigned_to_id")
  end

  def log_status_change
    old_status, new_status = previous_changes["status"]
    log_system_event("Status changed from #{old_status} to #{new_status}")
    linkable.log_system_event("Task '#{title}' status changed to #{new_status}") if linkable.respond_to?(:log_system_event)
  end

  def log_assignment_change
    old_id, new_id = previous_changes["assigned_to_id"]
    old_user = User.find_by(id: old_id)
    new_user = User.find_by(id: new_id)
    log_system_event("Reassigned from #{old_user&.name || 'unassigned'} to #{new_user&.name || 'unassigned'}")
    linkable.log_system_event("Task '#{title}' reassigned to #{new_user&.name || 'unassigned'}") if linkable.respond_to?(:log_system_event)
  end
end
