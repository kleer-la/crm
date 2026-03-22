class Proposal < ApplicationRecord
  include Loggable

  enum :status, { draft: 0, sent: 1, under_review: 2, won: 3, lost: 4, cancelled: 5 }

  belongs_to :linkable, polymorphic: true
  belongs_to :responsible_consultant, class_name: "User"
  has_many :consultant_assignments, as: :assignable, dependent: :destroy
  has_many :collaborating_consultants, through: :consultant_assignments, source: :user
  has_many :document_versions, dependent: :destroy
  has_many :tasks, as: :linkable, dependent: :restrict_with_error

  validates :title, presence: true
  validates :status, presence: true
  validates :responsible_consultant, presence: true
  validates :win_loss_reason, presence: true, if: -> { won? || lost? }
  validates :current_document_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  scope :open, -> { where(status: [ :draft, :sent, :under_review ]) }
  scope :closed, -> { where(status: [ :won, :lost, :cancelled ]) }

  after_commit :log_creation, on: :create
  after_commit :log_changes, on: :update

  private

  def log_creation
    log_system_event("Proposal created: #{title}")
  end

  def log_changes
    log_status_change if previous_changes.key?("status")
    log_consultant_change if previous_changes.key?("responsible_consultant_id")
    log_document_url_change if previous_changes.key?("current_document_url")
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

  def log_document_url_change
    old_url, new_url = previous_changes["current_document_url"]
    if old_url.blank?
      log_system_event("Document link added: #{new_url}")
    elsif new_url.blank?
      log_system_event("Document link removed")
    else
      log_system_event("Document link updated from #{old_url} to #{new_url}")
    end
  end
end
