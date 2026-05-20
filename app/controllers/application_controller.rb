class ApplicationController < ActionController::API
  before_action :authenticate_request!

  private

  def authenticate_request!
    token = extract_token_from_header
    payload = JwtService.decode_access_token(token)

    unless payload
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    @current_user = User.find_by(id: payload["user_id"])

    unless @current_user
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def extract_token_from_header
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end

  def skip_authentication
    skip_before_action :authenticate_request!
  end
end
