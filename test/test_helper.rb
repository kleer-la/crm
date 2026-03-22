ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    parallelize(workers: :number_of_processors)
  end
end

module ActionDispatch
  class IntegrationTest
    include FactoryBot::Syntax::Methods

    def sign_in(user)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: user.google_uid,
        info: {
          email: user.email,
          name: user.name,
          image: user.avatar_url
        }
      )
      get "/auth/google_oauth2/callback"
    end
  end
end

OmniAuth.config.test_mode = true
