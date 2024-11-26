FactoryBot.define do
  factory :question do
    title { Faker::Lorem.sentence }
    question_type { 'short' }
    is_required { false }
    survey_form
  end
end