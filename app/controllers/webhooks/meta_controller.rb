module Webhooks
  class MetaController < ActionController::API
    before_action :verify_signature, only: :receive

    # GET /webhooks/meta — Meta webhook verification
    def verify
      mode = params["hub.mode"]
      token = params["hub.verify_token"]
      challenge = params["hub.challenge"]

      if mode == "subscribe" && token == ENV["META_WEBHOOK_VERIFY_TOKEN"]
        render plain: challenge, status: :ok
      else
        head :forbidden
      end
    end

    # POST /webhooks/meta — Incoming messages
    def receive
      payload = JSON.parse(request.raw_post)
      MetaWebhookService.process(payload)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def verify_signature
      signature = request.headers["X-Hub-Signature-256"]
      return head :unauthorized unless signature

      body = request.raw_post
      secrets = [ ENV["META_APP_SECRET"], ENV["META_IG_APP_SECRET"] ].compact.reject(&:blank?)
      return head :unauthorized if secrets.empty?

      verified = secrets.any? do |secret|
        expected = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, body)}"
        ActiveSupport::SecurityUtils.secure_compare(signature, expected)
      end
      head :unauthorized unless verified
    end
  end
end
