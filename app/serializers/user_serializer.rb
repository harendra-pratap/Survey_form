class UserSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :full_phone_number, :country_code, :phone_number, :email
end
