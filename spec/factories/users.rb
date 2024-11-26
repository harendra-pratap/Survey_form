FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    full_phone_number { "+#{Faker::PhoneNumber.subscriber_number(length: 10)}" }
    country_code { 91 }
    phone_number { Faker::PhoneNumber.subscriber_number(length: 10) }
    email { Faker::Internet.email }
    password { 'password' }
  end
end