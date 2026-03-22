class Customer < ApplicationRecord
  include Loggable

  enum :status, { active: 0, inactive: 1, at_risk: 2 }

  belongs_to :responsible_consultant, class_name: "User"
  has_many :consultant_assignments, as: :assignable, dependent: :destroy
  has_many :collaborating_consultants, through: :consultant_assignments, source: :user
  has_many :contacts, dependent: :destroy
  has_many :proposals, as: :linkable, dependent: :restrict_with_error
  has_many :tasks, as: :linkable, dependent: :restrict_with_error

  validates :company_name, presence: true, uniqueness: true
  validates :status, presence: true
  validates :responsible_consultant, presence: true
  validates :date_became_customer, presence: true
  validates :last_activity_date, presence: true

  after_commit :log_creation, on: :create
  after_commit :log_changes, on: :update

  def recalculate_total_revenue!
    update!(total_revenue: proposals.where(status: :won).sum(:final_value))
  end

  private

  def log_creation
    log_system_event("Customer created: #{company_name}")
  end

  def log_changes
    log_status_change if previous_changes.key?("status")
    log_consultant_change if previous_changes.key?("responsible_consultant_id")
  end

  def log_status_change
    old_status, new_status = previous_changes["status"]
    log_system_event("Status changed from #{old_status} to #{new_status}")
  end

  def log_consultant_change
    old_id, new_id = previous_changes["responsible_consultant_id"]
    old_consultant = User.find_by(id: old_id)
    new_consultant = User.find_by(id: new_id)
    log_system_event("Responsible consultant changed from #{old_consultant&.name || 'unassigned'} to #{new_consultant&.name || 'unassigned'}")
  end
end
