class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :email
      t.string :full_name
      t.belongs_to :company, foreign_key: true
      t.belongs_to :country, foreign_key: true
      t.index :email, unique: true
      t.index :full_name, unique: true
      t.timestamps
    end
  end
end
