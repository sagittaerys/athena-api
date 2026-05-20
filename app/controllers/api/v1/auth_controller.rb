module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request!, only: [:register, :login]

      def register
        result = AuthService.register(
          email: params[:email],
          username: params[:username],
          password: params[:password]
        )

        render json: {
          user: serialize_user(result[:user]),
          access_token: result[:access_token],
          refresh_token: result[:refresh_token]
        }, status: :created

      rescue AuthService::AuthenticationError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def login
        result = AuthService.login(
          email: params[:email],
          password: params[:password]
        )

        render json: {
          user: serialize_user(result[:user]),
          access_token: result[:access_token],
          refresh_token: result[:refresh_token]
        }, status: :ok

      rescue AuthService::AuthenticationError => e
        render json: { error: e.message }, status: :unauthorized
      end

      def refresh
        result = AuthService.refresh(raw_token: params[:refresh_token])

        render json: {
          access_token: result[:access_token],
          refresh_token: result[:refresh_token]
        }, status: :ok

      rescue AuthService::InvalidTokenError => e
        render json: { error: e.message }, status: :unauthorized
      end

      def logout
        AuthService.logout(raw_token: params[:refresh_token])
        render json: { message: "Logged out successfully" }, status: :ok
      end

      private

      def serialize_user(user)
        {
          id: user.id,
          email: user.email,
          username: user.username,
          created_at: user.created_at
        }
      end
    end
  end
end