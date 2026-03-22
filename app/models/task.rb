class Task < ApplicationRecord
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

  private

  def due_date_not_in_past
    if due_date.present? && due_date < Date.current
      errors.add(:due_date, "cannot be in the past")
    end
  end
end
