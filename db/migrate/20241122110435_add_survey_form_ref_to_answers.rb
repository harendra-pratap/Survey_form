class AddSurveyFormRefToAnswers < ActiveRecord::Migration[7.2]
  def change
    add_reference :answers, :survey_form, null: false, foreign_key: true
  end
end
