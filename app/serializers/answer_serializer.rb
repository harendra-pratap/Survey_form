class AnswerSerializer < ActiveModel::Serializer
  attributes :id, :text, :question_id, :user_id, :mcq_option_id
end
