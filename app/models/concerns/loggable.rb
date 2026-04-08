module Loggable
  extend ActiveSupport::Concern

  included do
    has_many :activity_logs, as: :loggable, dependent: :destroy
  end

  def log_system_event(content, user: nil)
    activity_logs.create!(
      entry_type: :system,
      content: content,
      user: user,
      occurred_at: Time.current
    )
  end

  def log_touchpoint(touchpoint_type:, content:, user:, occurred_at: nil)
    activity_logs.create!(
      entry_type: :touchpoint,
      touchpoint_type: touchpoint_type,
      content: content,
      user: user,
      occurred_at: occurred_at || Time.current
    )
  end
end
