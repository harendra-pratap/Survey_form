class McqOption < ApplicationRecord
  belongs_to :question
  has_one :answer

  validates :text, presence: true
end
