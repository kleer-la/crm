module Webhooks
  class KapsoController < ActionController::API
    before_action :verify_signature

    # POST /webhooks/kapso — Incoming Kapso events
    def receive
      payload = JSON.parse(request.raw_post)

      # Kapso v2 sends message/conversation at root level (via X-Webhook-Event header)
      # Kapso v1 wraps in { event, data }
      data = if payload.key?("message")
               payload
      elsif payload.key?("data")
               payload["data"]
      end

      KapsoWebhookService.process(data) if data&.key?("message")

      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def verify_signature
      signature = request.headers["X-Webhook-Signature"]
      return head :unauthorized unless signature

      expected = OpenSSL::HMAC.hexdigest("SHA256", ENV["KAPSO_WEBHOOK_SECRET"].to_s, request.raw_post)
      head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(signature, expected)
    end
  end
end
