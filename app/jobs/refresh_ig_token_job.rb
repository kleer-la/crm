class RefreshIgTokenJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # Instagram-login tokens expire after 60 days with no permanent option, but
  # can be renewed any time between 24 hours old and expiry, resetting the
  # clock. Runs weekly via config/recurring.yml.
  def perform
    token = Setting.ig_access_token
    if token.blank?
      Rails.logger.error("[RefreshIgToken] No IG access token configured, skipping")
      return
    end

    response = refresh_request(token)
    data = JSON.parse(response.body)

    if response.is_a?(Net::HTTPSuccess) && data["access_token"].present?
      Setting.set("ig_access_token", data["access_token"])
      Rails.logger.info("[RefreshIgToken] Token refreshed, expires in #{data["expires_in"].to_i / 86_400} days")
    else
      raise "IG token refresh failed (HTTP #{response.code}): #{data}"
    end
  end

  private

  def refresh_request(token)
    uri = URI("https://graph.instagram.com/refresh_access_token")
    uri.query = URI.encode_www_form(grant_type: "ig_refresh_token", access_token: token)
    Net::HTTP.get_response(uri)
  end
end
