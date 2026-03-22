class Proposal < ApplicationRecord
  enum :status, { draft: 0, sent: 1, under_review: 2, won: 3, lost: 4, cancelled: 5 }

  belongs_to :linkable, polymorphic: true
  belongs_to :responsible_consultant, class_name: "User"
  has_many :consultant_assignments, as: :assignable, dependent: :destroy
  has_many :collaborating_consultants, through: :consultant_assignments, source: :user
  has_many :document_versions, dependent: :destroy
  has_many :tasks, as: :linkable, dependent: :restrict_with_error
  has_many :activity_logs, as: :loggable, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true
  validates :responsible_consultant, presence: true
  validates :win_loss_reason, presence: true, if: -> { won? || lost? }
  validates :current_document_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  scope :open, -> { where(status: [ :draft, :sent, :under_review ]) }
  scope :closed, -> { where(status: [ :won, :lost, :cancelled ]) }
end
