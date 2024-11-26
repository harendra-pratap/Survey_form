require 'rails_helper'

RSpec.describe Question, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should allow_value(true, false).for(:is_required) }
  end

  describe 'associations' do
    it { should belong_to(:survey_form) }
    it { should have_many(:mcq_options).dependent(:destroy) }
  end
end
