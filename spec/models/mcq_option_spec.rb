require 'rails_helper'

RSpec.describe McqOption, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:text) }
  end

  describe 'associations' do
    it { should belong_to(:question) }
  end
end
