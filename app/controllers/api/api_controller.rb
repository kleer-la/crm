module Api
  WEBHOOK_TOKEN = "WEBHOOK_TOKEN".freeze

  class ApiController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

    before_action :authenticate

    private

    def handle_not_found
      render json: { message: "Record not found" }, status: :not_found
    end

    def authenticate
      authenticate_user_with_token || handle_bad_authentication
    end

    def authenticate_user_with_token
      return true if Rails.env.development? || Rails.env.test?

      authenticate_with_http_token do |token|
        api_key = ENV.fetch(WEBHOOK_TOKEN) { |key| raise("#{key} environment variable is not set") }
        ActiveSupport::SecurityUtils.secure_compare(token, api_key)
      end
    end

    def handle_bad_authentication
      render json: { message: "Bad credentials" }, status: :unauthorized
    end
  end
end
