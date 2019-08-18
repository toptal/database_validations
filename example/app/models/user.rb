class User < ApplicationRecord
  db_belongs_to :country
  db_belongs_to :company

  validates :full_name, :email, db_uniqueness: true
end
