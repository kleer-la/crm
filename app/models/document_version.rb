class DocumentVersion < ApplicationRecord
  belongs_to :proposal
  belongs_to :archived_by, class_name: "User"

  validates :label, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }
  validates :archived_at, presence: true

  before_update { raise ActiveRecord::ReadOnlyRecord, "DocumentVersion records are immutable" }

  def readonly?
    false
  end
end
