require 'rails_helper'

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_params) do
      {
        email: "test@athena.com",
        username: "testuser",
        password: "password123"
      }
    end

    context "with valid params" do
      it "returns 201 and tokens" do
        post "/api/v1/auth/register", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response).to include("access_token", "refresh_token", "user")
      end

      it "creates a new user" do
        expect {
          post "/api/v1/auth/register", params: valid_params, as: :json
        }.to change(User, :count).by(1)
      end

      it "never returns password_digest" do
        post "/api/v1/auth/register", params: valid_params, as: :json
        expect(json_response["user"]).not_to include("password_digest")
      end
    end

    context "with invalid params" do
      it "returns 422 with error message" do
        post "/api/v1/auth/register",
             params: { email: "bad", username: "x", password: "short" },
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include("error")
      end
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, password: "password123") }

    context "with valid credentials" do
      it "returns 200 and tokens" do
        post "/api/v1/auth/login",
             params: { email: user.email, password: "password123" },
             as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response).to include("access_token", "refresh_token", "user")
      end
    end

    context "with invalid credentials" do
      it "returns 401" do
        post "/api/v1/auth/login",
             params: { email: user.email, password: "wrongpassword" },
             as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include("error")
      end
    end
  end

  describe "POST /api/v1/auth/refresh" do
    let!(:user) { create(:user) }
    let!(:refresh_token) { JwtService.generate_refresh_token(user.id) }
    let!(:access_token) { JwtService.generate_access_token(user.id) }

    it "returns new tokens" do
      post "/api/v1/auth/refresh",
           params: { refresh_token: refresh_token },
           headers: { "Authorization" => "Bearer #{access_token}" },
           as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to include("access_token", "refresh_token")
    end

    it "returns 401 with invalid refresh token" do
      post "/api/v1/auth/refresh",
           params: { refresh_token: "invalidtoken" },
           headers: { "Authorization" => "Bearer #{access_token}" },
           as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let!(:user) { create(:user) }
    let!(:refresh_token) { JwtService.generate_refresh_token(user.id) }
    let!(:access_token) { JwtService.generate_access_token(user.id) }

    it "returns 200 and logs out" do
      delete "/api/v1/auth/logout",
             params: { refresh_token: refresh_token },
             headers: { "Authorization" => "Bearer #{access_token}" },
             as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response["message"]).to eq("Logged out successfully")
    end
  end
end