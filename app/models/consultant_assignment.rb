class ConsultantAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :assignable, polymorphic: true

  validates :user_id, uniqueness: { scope: [ :assignable_type, :assignable_id ] }

  after_create_commit :log_addition
  after_destroy_commit :log_removal

  private

  def log_addition
    return unless assignable.respond_to?(:log_system_event)

    assignable.log_system_event("Collaborating consultant added: #{user.name}")
  end

  def log_removal
    return unless assignable.respond_to?(:log_system_event)

    assignable.log_system_event("Collaborating consultant removed: #{user.name}")
  end
end
