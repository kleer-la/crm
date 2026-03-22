class Contact < ApplicationRecord
  belongs_to :customer

  validates :name, presence: true
  validates :email, presence: true
end
