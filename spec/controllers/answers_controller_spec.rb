require 'rails_helper'

RSpec.describe AnswersController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:survey_form) { FactoryBot.create(:survey_form) }
  let(:question) { FactoryBot.create(:question, survey_form: survey_form) }
  let(:mcq_option) { FactoryBot.create(:mcq_option, question: question) }
  let(:valid_answer_params) { { text: "Test Answer", question_id: question.id } }
  let(:invalid_answer_params) { { text: "", question_id: question.id, mcq_option_id: mcq_option.id } }

  let(:auth_token) { JsonWebToken.encode_token(user_id: user.id) }

  before do
    request.headers['Authorization'] = "Bearer #{auth_token}"
  end


  describe 'GET #index' do
    it 'returns a list of answers' do
      answer = FactoryBot.create(:answer, user: user, survey_form: survey_form, question: question)

      get :index

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['survey_forms'].first['survey_form']['id']).to eq(survey_form.id)
    end

    it 'returns no answers when the user has no answers' do
      get :index

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['message']).to eq("No answers found for the user")
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new answer and returns a success message' do
        post :create, params: { survey_form_id: survey_form.id, answers: [valid_answer_params] }

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq("Answers saved successfully")
      end
    end

    context 'with invalid parameters' do
      it 'returns an error when answer text is missing' do
        post :create, params: { survey_form_id: survey_form.id, answers: [invalid_answer_params] }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include({
          "question_id" => question.id,
          "errors" => ["Text can't be blank", "Mcq option should not be provided for a short answer question"]
        })
      end
    end

    context 'with not passing question_id' do
      let(:invalid_answers) { { text: "hi there"} }
      it 'returns an error for blank question_id' do

        post :create, params: { survey_form_id: survey_form.id, answers: [invalid_answers] }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ "error" => "Question ID must be present for all answers" })
      end
    end

    context 'when one or more answers are invalid' do
      let(:valid_answer) { { text: "Valid Answer", question_id: question.id } }
      let(:invalid_answer) { { text: "", question_id: question.id, mcq_option_id: mcq_option.id } }

      it 'triggers a rollback and returns errors' do
        post :create, params: { survey_form_id: survey_form.id, answers: [valid_answer, invalid_answer] }

        expect(response).to have_http_status(:unprocessable_entity)
        response_body = JSON.parse(response.body)
        expect(response_body['errors']).to include({
          "question_id" => question.id,
          "errors" => [
            "Text can't be blank",
            "Question You can only answer this question once.",
            "Mcq option should not be provided for a short answer question"
          ]
        })
        expect(user.answers.count).to eq(0)
      end
    end
  end

  describe 'GET #show' do
    let(:survey_form) { FactoryBot.create(:survey_form) }
    let(:question) { FactoryBot.create(:question, survey_form: survey_form) }
    let(:mcq_option) { FactoryBot.create(:mcq_option, question: question) }
    let(:answer) { FactoryBot.create(:answer, user: user, survey_form: survey_form, question: question) }

    context 'when the survey form exists' do
      it 'returns the survey form with its questions and answers' do
        question.reload
        survey_form.reload
        answer.reload
        get :show, params: { id: survey_form.id }

        expect(response).to have_http_status(:ok)
        
        parsed_response = JSON.parse(response.body)
        
        expect(parsed_response['survey_form']['id']).to eq(survey_form.id)
        expect(parsed_response['survey_form']['title']).to eq(survey_form.title)

        question_with_answer = parsed_response['survey_form']['questions'].first
        expect(question_with_answer['id']).to eq(question.id)
        expect(question_with_answer['title']).to eq(question.title)
        expect(question_with_answer['question_type']).to eq(question.question_type)
      end
    end

    context 'when the survey form does not exist' do
      it 'returns an error message' do
        get :show, params: { id: 9999 }

        expect(response).to have_http_status(:not_found)
        
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['error']).to eq('Survey form not found')
      end
    end
  end

  describe 'PUT #update' do
    let(:required_question) { FactoryBot.create(:question, survey_form: survey_form, is_required: true) }
    let!(:answer) { FactoryBot.create(:answer, user: user, survey_form: survey_form, question: question) }
    let(:required_answer) { FactoryBot.create(:answer, user: user, survey_form: survey_form, question: required_question) }

    context 'with valid parameters' do
      it 'updates the answer and returns a success message' do
        updated_params = {
          answers: [
            {
              id: answer.id,
              question_id: question.id,
              text: "Updated Answer"
            }
          ]
        }

        put :update, params: updated_params

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to eq("Answers updated successfully")
        expect(parsed_response['answers'].first['id']).to eq(answer.id)
        expect(answer.reload.text).to eq("Updated Answer")
      end
    end

    context 'with missing text for a required question' do
      it 'returns an error and does not update the answer' do
        invalid_params = {
          answers: [
            {
              id: required_answer.id,
              question_id: required_question.id,
              text: ""
            }
          ]
        }

        put :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ "error" => "Answer is required for question #{required_question.id}" })
      end
    end

    context 'with invalid parameters' do
      it 'returns an error when answer text is missing' do
        invalid_updated_params = {
          answers: [
            {
              id: answer.id,
              text: ""
            }
          ]
        }
        updated_params = { text: "" }
        put :update, params: invalid_updated_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include({ "id" => answer.id, "errors" => ["Text can't be blank"] })
      end
    end

    context 'when the answer is not found or not authorized' do
      it 'returns an error message' do
        unauthorized_params = {
          answers: [
            {
              id: 999,
              question_id: question.id,
              text: "Updated Answer"
            }
          ]
        }

        put :update, params: unauthorized_params

        expect(response).to have_http_status(:unprocessable_entity)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['errors'].first['errors']).to include("Answer not found or not authorized to update")
      end
    end

    context 'when deleting an optional answer' do
      it 'deletes the answer and returns a success message' do
        delete_params = {
          answers: [
            {
              id: answer.id,
              question_id: question.id,
              "deleted": true
            }
          ]
        }

        put :update, params: delete_params, as: :json

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to eq("Answers updated successfully")
        expect(parsed_response['deleted_answers'].first['id']).to eq(answer.id)
      end
    end

    context 'when trying to delete a required answer' do
      it 'returns an error and does not delete the answer' do
        delete_params = {
          answers: [
            {
              id: required_answer.id,
              question_id: required_question.id,
              "deleted": true
            }
          ]
        }
        put :update, params: delete_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        parsed_response = JSON.parse(response.body)
        expect(JSON.parse(response.body)).to eq({ "error" => "Answer is required for question #{required_question.id}" })
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with authorized user' do
      it 'deletes the answer and returns a success message' do
        answer = FactoryBot.create(:answer, user: user, survey_form: survey_form, question: question)
        delete :destroy, params: { id: answer.id }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq("Answer deleted successfully")
        expect(Answer.exists?(answer.id)).to be_falsey
      end
    end

    context 'with authorized user' do
      it 'throws errors for answer not found' do
        delete :destroy, params: { id: 55 }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ "error" => "Answer not found" })
      end
    end

    context 'with anuthorized user' do
      it 'returns an error if the user is not authorized to delete the answer' do
        another_user = FactoryBot.create(:user)
        answer = FactoryBot.create(:answer, user: another_user, survey_form: survey_form, question: question)
        delete :destroy, params: { id: answer.id }

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq("You are not authorized to delete this answer")
      end
    end
  end

  describe 'GET #download_csv' do
    context 'when authorized user hit the download csv' do
      it 'returns a CSV file for the answers' do
        another_user = FactoryBot.create(:user)
        FactoryBot.create(:answer, user: another_user, survey_form: survey_form, question: question)
        survey_form.update(user_id: user.id)

        get :download_csv, params: { survey_form_id: survey_form.id }
        expect(response).to have_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to start_with('attachment; filename="')
        expect(response.body).to include('text')
        expect(response.body).to include('answer')
      end

      it 'returns a not_found status when no answers are found' do
        Answer.destroy_all
        survey_form.update(user_id: user.id)
        get :download_csv, params: { survey_form_id: survey_form.id }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['message']).to eq("No answers found for this survey form")
      end

      it 'returns a not_found status when survey_form not found' do
        get :download_csv, params: { survey_form_id: 980 }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq("Survey form not found")
      end
    end

    context 'when an unauthorizes user hit the download csv' do
      it 'returns a unauthorized error' do
        another_user = FactoryBot.create(:user)
        request.headers['Authorization'] = "Bearer #{JsonWebToken.encode_token(user_id: another_user.id)}"

        get :download_csv, params: { survey_form_id: survey_form.id }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq("You are not authorized to access this resource")
      end
    end
  end
end
