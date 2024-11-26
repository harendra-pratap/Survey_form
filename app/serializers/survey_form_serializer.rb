class SurveyFormSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :user_id

  has_many :questions
end
