class SurveyForm < ApplicationRecord
  belongs_to :user
  has_many :questions, dependent: :destroy

  accepts_nested_attributes_for :questions, allow_destroy: true

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 1000 }
end