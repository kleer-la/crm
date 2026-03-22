class User < ApplicationRecord
  enum :role, { pending: 0, consultant: 1, admin: 2 }

  has_many :consultant_assignments, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true

  scope :active, -> { where(active: true) }
  scope :assignable, -> { active.where.not(role: :pending) }

  def display_name
    active? ? name : "(Deactivated) #{name}"
  end
end
