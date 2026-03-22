class ConsultantAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :assignable, polymorphic: true

  validates :user_id, uniqueness: { scope: [ :assignable_type, :assignable_id ] }
end
