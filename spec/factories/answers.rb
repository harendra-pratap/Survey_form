# FactoryBot.define do
#   factory :answer do
#     text { "qwertyuiopasdfghjklzxcvbnm"}
#     user
#     question
#     survey_form
#   end
# end

FactoryBot.define do
  factory :answer do
    text { "Sample answer text" }
    
    # Associations
    association :user
    association :question
    association :survey_form
  end
end
