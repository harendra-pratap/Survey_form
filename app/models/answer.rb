class Answer < ApplicationRecord
  belongs_to :question
  belongs_to :user
  belongs_to :mcq_option, optional: true
  belongs_to :survey_form

  validates :text, presence: true, if: :text_answer?
  validates :mcq_option_id, presence: true, if: :mcq_answer?
  validates :question_id, uniqueness: { scope: :user_id, message: "You can only answer this question once." }, on: :create

  validate :validate_answer_for_question_type
  validate :ensure_question_present
  
  private

  def ensure_question_present
    errors.add(:question, "must be present") if question.nil?
  end

  def text_answer?
    question.present? && (question.short? || question.paragraph?)
  end

  def mcq_answer?
    question.present? && question.mcq?
  end

  def validate_answer_for_question_type
    if question.present?
      case question.question_type
      when 'mcq'
        errors.add(:text, "should not be filled for an MCQ question") if text.present?
      when 'short'
        errors.add(:mcq_option_id, "should not be provided for a short answer question") if mcq_option_id.present?
        errors.add(:text, "must not exceed 100 characters for a short answer question") if text.present? && text.length > 100
      when 'paragraph'
        errors.add(:text, "must be between 100 and 500 characters for a paragraph question") if text.length < 100 || text.length > 500
      end
    end
  end
end
