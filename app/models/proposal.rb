class Proposal < ApplicationRecord
  include Loggable
  include PgSearch::Model

  pg_search_scope :search_by_title, against: :title, using: { trigram: { threshold: 0.1 } }

  enum :status, { draft: 0, sent: 1, under_review: 2, won: 3, lost: 4, cancelled: 5 }

  belongs_to :linkable, polymorphic: true
  belongs_to :responsible_consultant, class_name: "User"
  has_many :consultant_assignments, as: :assignable, dependent: :destroy
  has_many :collaborating_consultants, through: :consultant_assignments, source: :user
  has_many :document_versions, dependent: :destroy
  has_many :tasks, as: :linkable, dependent: :restrict_with_error

  validates :title, presence: true
  validates :description, presence: true
  validates :status, presence: true
  validates :responsible_consultant, presence: true
  validates :win_loss_reason, presence: true, if: -> { won? || lost? }
  validates :current_document_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  validate :cannot_win_if_prospect_disqualified, if: :won?

  scope :open, -> { where(status: [ :draft, :sent, :under_review ]) }
  scope :closed, -> { where(status: [ :won, :lost, :cancelled ]) }
  STALE_DAYS = 30

  scope :stale, -> {
    open.where.not(
      id: ActivityLog.where(loggable_type: "Proposal")
                     .where(entry_type: :touchpoint)
                     .where("created_at >= ?", STALE_DAYS.days.ago)
                     .select(:loggable_id)
    )
  }
  scope :pending_conversion, -> {
    joins("INNER JOIN prospects ON proposals.linkable_type = 'Prospect' AND proposals.linkable_id = prospects.id")
      .where(status: :won)
      .where.not(prospects: { status: Prospect.statuses[:converted] })
  }

  before_validation :auto_set_dates

  after_commit :log_creation, on: :create
  after_commit :log_changes, on: :update
  after_commit :recalculate_customer_revenue, on: [ :create, :update ]

  def duplicate
    Proposal.new(
      title: title,
      description: description,
      linkable: linkable,
      responsible_consultant: responsible_consultant,
      estimated_value: estimated_value,
      notes: notes,
      status: :draft
    )
  end

  def pending_conversion?
    won? && linkable.is_a?(Prospect) && !linkable.converted?
  end

  private

  def auto_set_dates
    if status_changed?
      self.date_sent ||= Date.current if sent?
      self.actual_close_date ||= Date.current if won? || lost? || cancelled?
    end
  end

  def cannot_win_if_prospect_disqualified
    if linkable.is_a?(Prospect) && linkable.disqualified?
      errors.add(:base, "Cannot mark as Won when linked Prospect is disqualified. Change the Prospect's status first.")
    end
  end

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

  def recalculate_customer_revenue
    return unless linkable.is_a?(Customer)
    return unless previous_changes.key?("status") || previous_changes.key?("estimated_value")

    linkable.recalculate_total_revenue!
  end
end
