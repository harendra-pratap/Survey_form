require 'rails_helper'

RSpec.describe Answer, type: :model do
  let(:question) { FactoryBot.create(:question, question_type: 'short') }
  let(:user) { FactoryBot.create(:user) }
  let(:survey_form) { FactoryBot.create(:survey_form) }

  describe 'validations' do
    subject { Answer.new(question: question, user: user, survey_form: survey_form, text: "Sample text") }

    it { should validate_presence_of(:text).on(:create) }

    context 'custom validations' do
      it 'validates presence of text for short answer questions' do
        question.update!(question_type: 'short')
        answer = Answer.new(question: question, user: user, survey_form: survey_form, text: nil)

        expect(answer).to be_invalid
        expect(answer.errors[:text]).to include("can't be blank")
      end

      it 'validates text length for short answer questions' do
        question.update!(question_type: 'short')
        answer = Answer.new(question: question, user: user, survey_form: survey_form, text: 'a' * 101)

        expect(answer).to be_invalid
        expect(answer.errors[:text]).to include("must not exceed 100 characters for a short answer question")
      end
    end
  end
end
