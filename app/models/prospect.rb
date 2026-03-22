class Prospect < ApplicationRecord
  enum :source, { referral: 0, inbound: 1, outbound: 2, event: 3, other: 4 }
  enum :status, { new_prospect: 0, contacted: 1, qualified: 2, disqualified: 3, converted: 4 }

  belongs_to :responsible_consultant, class_name: "User"
  has_many :consultant_assignments, as: :assignable, dependent: :destroy
  has_many :collaborating_consultants, through: :consultant_assignments, source: :user
  has_many :proposals, as: :linkable, dependent: :restrict_with_error
  has_many :tasks, as: :linkable, dependent: :restrict_with_error
  has_many :activity_logs, as: :loggable, dependent: :destroy

  belongs_to :converted_customer, class_name: "Customer", optional: true

  validates :company_name, presence: true, uniqueness: true
  validates :primary_contact_name, presence: true
  validates :primary_contact_email, presence: true, uniqueness: true
  validates :status, presence: true
  validates :responsible_consultant, presence: true
  validates :date_added, presence: true
  validates :last_activity_date, presence: true
  validates :disqualification_reason, presence: true, if: :disqualified?

  def read_only?
    converted?
  end
end
