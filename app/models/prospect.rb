class Prospect < ApplicationRecord
  include Loggable
  include PgSearch::Model

  pg_search_scope :search_by_name, against: :company_name, using: { trigram: { threshold: 0.3 } }

  enum :source, { referral: 0, inbound: 1, outbound: 2, event: 3, other: 4 }
  enum :status, { new_prospect: 0, contacted: 1, qualified: 2, disqualified: 3, converted: 4 }

  belongs_to :responsible_consultant, class_name: "User"
  has_many :consultant_assignments, as: :assignable, dependent: :destroy
  has_many :collaborating_consultants, through: :consultant_assignments, source: :user
  has_many :proposals, as: :linkable, dependent: :restrict_with_error
  has_many :tasks, as: :linkable, dependent: :restrict_with_error

  belongs_to :converted_customer, class_name: "Customer", optional: true

  validates :company_name, presence: true, uniqueness: true
  validates :primary_contact_name, presence: true
  validates :primary_contact_email, presence: true, uniqueness: true
  validates :status, presence: true
  validates :responsible_consultant, presence: true
  validates :date_added, presence: true
  validates :last_activity_date, presence: true
  validates :disqualification_reason, presence: true, if: :disqualified?

  validate :company_name_unique_across_customers
  validate :email_unique_across_customer_contacts

  before_validation :normalize_country

  after_commit :log_creation, on: :create
  after_commit :log_changes, on: :update

  def read_only?
    converted?
  end

  private

  def company_name_unique_across_customers
    return if company_name.blank?
    return if converted?

    if Customer.where(company_name: company_name).exists?
      errors.add(:company_name, "is already taken by an existing customer")
    end
  end

  def email_unique_across_customer_contacts
    return if primary_contact_email.blank?
    return if converted?

    if Contact.where(email: primary_contact_email).exists?
      errors.add(:primary_contact_email, "is already used by an existing customer contact")
    end
  end

  def normalize_country
    self.country = country.presence
  end

  def log_creation
    log_system_event("Prospect created: #{company_name}")
  end

  def log_changes
    log_status_change if previous_changes.key?("status")
    log_consultant_change if previous_changes.key?("responsible_consultant_id")
    log_conversion if previous_changes.key?("converted_customer_id") && converted_customer_id.present?
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

  def log_conversion
    log_system_event("Converted to customer: #{converted_customer.company_name}")
  end
end
