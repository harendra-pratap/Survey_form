class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :title, :question_type, :is_required, :survey_form_id, :mcq_options

  has_many :mcq_options, if: :mcq_type?

  def mcq_type?
    object.question_type == "mcq"
  end
end
