class Question < ApplicationRecord
  belongs_to :survey_form
  has_one :answer, dependent: :destroy
  has_many :mcq_options, dependent: :destroy

  enum question_type: { short: 0, paragraph: 1, mcq: 2}

  accepts_nested_attributes_for :mcq_options, allow_destroy: true

  validates :title, presence: true, length: { maximum: 255 }
  validates :is_required, inclusion: { in: [true, false] }
  validate :validate_mcq_options_for_mcq_type

  private

  def validate_mcq_options_for_mcq_type
    if question_type == 'mcq' && mcq_options.blank?
      errors.add(:mcq_options, 'must be present for MCQ questions')
    elsif question_type != 'mcq' && mcq_options.any?
      errors.add(:mcq_options, 'cannot be present for non-MCQ questions')
    end
  end
end
