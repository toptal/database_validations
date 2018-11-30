class User < ApplicationRecord
  db_belongs_to :country
  db_belongs_to :company

  validates_db_uniqueness_of :email
  validates_db_uniqueness_of :full_name
end
