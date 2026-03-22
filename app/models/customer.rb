class Customer < ApplicationRecord
  enum :status, { active: 0, inactive: 1, at_risk: 2 }

  belongs_to :responsible_consultant, class_name: "User"
  has_many :consultant_assignments, as: :assignable, dependent: :destroy
  has_many :collaborating_consultants, through: :consultant_assignments, source: :user
  has_many :contacts, dependent: :destroy
  has_many :proposals, as: :linkable, dependent: :restrict_with_error
  has_many :tasks, as: :linkable, dependent: :restrict_with_error
  has_many :activity_logs, as: :loggable, dependent: :destroy

  validates :company_name, presence: true, uniqueness: true
  validates :status, presence: true
  validates :responsible_consultant, presence: true
  validates :date_became_customer, presence: true
  validates :last_activity_date, presence: true

  def recalculate_total_revenue!
    update!(total_revenue: proposals.where(status: :won).sum(:final_value))
  end
end
