class UsersController < ApplicationController
  before_action :authorize_request, except: [:create, :login]

  def create
    user = User.new(user_params)
    if user.save
      token = JsonWebToken.encode_token({ user_id: user.id })
      render json: { message: "User created successfully", user: UserSerializer.new(user).serializable_hash, token: token }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      token = JsonWebToken.encode_token({ user_id: user.id })
      render json: { token: token, user: UserSerializer.new(user).serializable_hash }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def show
    render json: UserSerializer.new(@current_user).serializable_hash, status: :ok
  end

  def update
    if@current_user&.update(user_params)
      render json: { message: "User updated successfully", user: UserSerializer.new(@current_user).serializable_hash }, status: :ok
    else
      render json: { errors: @current_user&.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @current_user.destroy
    # render json: { message: "User deleted successfully" }, status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :full_phone_number, :country_code, :phone_number, :email, :password)
  end
end
