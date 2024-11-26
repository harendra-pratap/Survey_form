require 'rails_helper'

RSpec.describe SurveyForm, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:questions).dependent(:destroy) }
  end
end
