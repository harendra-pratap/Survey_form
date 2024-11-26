require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:valid_attributes) do
    {
      first_name: 'John',
      last_name: 'Doe',
      full_phone_number: '+11234567890',
      country_code: 1,
      phone_number: '1234567890',
      email: 'john.doe@example.com',
      password: 'password123'
    }
  end

  let(:invalid_attributes) do
    {
      first_name: '',
      last_name: '',
      email: 'invalid_email',
      phone_number: '123'
    }
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new user' do
        post :create, params: { user: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to include('message' => 'User created successfully')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new user' do
        expect {
          post :create, params: { user: invalid_attributes }
        }.to_not change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end
    end
  end

  describe 'POST #login' do
    let!(:user) { FactoryBot.create(:user, email: valid_attributes[:email], password: valid_attributes[:password]) }

    context 'with valid credentials' do
      it 'returns a valid token' do
        post :login, params: { email: user.email, password: valid_attributes[:password] }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('token')
      end
    end

    context 'with invalid credentials' do
      it 'returns an unauthorized error' do
        post :login, params: { email: user.email, password: 'wrong_password' }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include('error' => 'Invalid email or password')
      end
    end
  end

  describe 'GET #show' do
    let!(:user) { FactoryBot.create(:user) }
    let(:token) { JsonWebToken.encode_token(user_id: user.id) }

    before { request.headers['Authorization'] = "Bearer #{token}" }

    it 'returns the current user' do
      get :show

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('id' => user.id)
    end
  end

  describe 'PUT #update' do
    let!(:user) { FactoryBot.create(:user) }
    let(:token) { JsonWebToken.encode_token(user_id: user.id) }

    before { request.headers['Authorization'] = "Bearer #{token}" }

    context 'with valid parameters' do
      it 'updates the user' do
        put :update, params: { user: { first_name: 'Updated', password: 'securepassword123' } }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('message' => 'User updated successfully')
        expect(user.reload.first_name).to eq('Updated')
      end
    end

    context 'with invalid parameters' do
      it 'returns an error' do
        put :update, params: { user: { email: '' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('errors')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:user) { FactoryBot.create(:user) }
    let(:token) { JsonWebToken.encode_token(user_id: user.id) }

    before { request.headers['Authorization'] = "Bearer #{token}" }

    it 'deletes the user' do
      expect {
        delete :destroy
      }.to change(User, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
