require 'rails_helper'

RSpec.describe SurveyFormsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }  # Assuming you have a user factory
  let(:valid_attributes) do
    {
      title: "Test Survey",
      description: "Test Description",
      questions_attributes: [
        {
          title: "Question 1",
          question_type: "mcq",
          is_required: true,
          mcq_options_attributes: [
            { text: "Option 1" },
            { text: "Option 2" }
          ]
        },
        {
          title: "Question 2",
          question_type: "short",
          is_required: false
        }
      ]
    }
  end

  let(:invalid_attributes) do
    {
      title: nil,
      description: nil
    }
  end

  let(:auth_token) { JsonWebToken.encode_token(user_id: user.id) }

  before do
    request.headers['Authorization'] = "Bearer #{auth_token}"
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new survey form' do
        expect {
          post :create, params: { survey_form: valid_attributes }
        }.to change(SurveyForm, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to include('message' => 'Survey form created successfully')
      end
    end

    context 'with invalid attributes' do
      it 'does not create a new survey form' do
        expect {
          post :create, params: { survey_form: invalid_attributes }
        }.to_not change(SurveyForm, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Title can't be blank", "Description can't be blank")
      end
    end
  end

  describe 'GET #show' do
    let!(:survey_form) { FactoryBot.create(:survey_form, user: user) }

    it 'returns the survey form' do
      get :show, params: { id: survey_form.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["title"]).to eq(survey_form.title)

    end

    it 'returns an error if the survey form is not found' do
      get :show, params: { id: 999 }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Survey Form not found")
    end
  end

  describe 'PUT #update' do
    let!(:survey_form) { FactoryBot.create(:survey_form, user: user) }

    context 'with valid attributes' do
      it 'updates the survey form' do
        put :update, params: { id: survey_form.id, survey_form: { title: 'Updated Title' } }

        survey_form.reload
        expect(survey_form.title).to eq('Updated Title')
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('message' => 'Survey form updated successfully')
      end
    end

    context 'with invalid attributes' do
      it 'does not update the survey form' do
        put :update, params: { id: survey_form.id, survey_form: { title: nil } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Title can't be blank")
      end
    end

    context 'with valid attributes for non exisitng survey_form' do
      it 'throw not found error' do
        put :update, params: { id: 998, survey_form: { title: 'Updated Title' } }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Survey form not found')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:survey_form) { FactoryBot.create(:survey_form, user: user) }

    it 'deletes the survey form' do
      expect {
        delete :destroy, params: { id: survey_form.id }
      }.to change(SurveyForm, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('message' => 'Survey form deleted successfully')
    end
  end
end
