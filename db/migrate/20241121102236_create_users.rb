class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :full_phone_number
      t.integer :country_code
      t.bigint :phone_number
      t.string :email
      t.string :password_digest
      t.timestamps
    end
  end
end
