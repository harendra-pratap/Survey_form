class ApplicationController < ActionController::API
  include JsonWebToken

  def current_user
    header = request.headers['Authorization']
    if header
      token = header.split(' ').last
      decoded = JsonWebToken.decode_token(token)
      @current_user = User.find(decoded["user_id"]) if decoded && decoded["user_id"]
    end
  rescue JWT::DecodeError
    nil
  end

  def authorize_request
    @current_user ||= current_user
    render json: { error: 'Not Authorized' }, status: :unauthorized unless @current_user
  end
end
