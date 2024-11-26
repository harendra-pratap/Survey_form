class CreateQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :questions do |t|
      t.string :title
      t.integer :question_type, default: 0
      t.boolean :is_required, default: false
      t.references :survey_form, null: false, foreign_key: true
      t.timestamps
    end
  end
end
