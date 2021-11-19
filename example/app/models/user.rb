class User < ApplicationRecord
  db_belongs_to :country
  db_belongs_to :company

  validates :full_name, db_uniqueness: true
  validates :email, db_uniqueness: { rescue: :always }
end
