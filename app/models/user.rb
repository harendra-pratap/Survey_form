class User < ApplicationRecord
  has_secure_password

  has_many :survey_forms, dependent: :destroy
  has_many :answers, dependent: :destroy

  validates :first_name, presence: true, length: { maximum: 25 }
  validates :last_name, presence: true, length: { maximum: 25 }
  validates :full_phone_number, presence: true, length: { maximum: 15 }, uniqueness: true
  validates :country_code, presence: true, numericality: { only_integer: true }
  validates :phone_number, presence: true, numericality: { only_integer: true }, length: { is: 10 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }
end
