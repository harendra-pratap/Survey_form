class CreateAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :answers do |t|
      t.text :text, null: true
      t.references :question, null: false, foreign_key: true 
      t.references :user, null: false, foreign_key: true
      t.references :mcq_option, null: true, foreign_key: true
      t.timestamps
    end
  end
end
