class CreateMcqOptions < ActiveRecord::Migration[7.2]
  def change
    create_table :mcq_options do |t|
      t.string :text
      t.references :question, null: false, foreign_key: true

      t.timestamps
    end
  end
end
