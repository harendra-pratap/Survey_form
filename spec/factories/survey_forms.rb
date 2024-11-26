FactoryBot.define do
  factory :survey_form do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    user
  end
end