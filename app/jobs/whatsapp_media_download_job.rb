class WhatsappMediaDownloadJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  MEDIA_TYPES = %w[image audio video document sticker].freeze

  def perform(message)
    return if message.file.attached?

    media = message.metadata[message.message_type]
    media_id = media&.dig("id")
    return if media_id.blank?

    info = fetch_media_info(media_id)
    url = info["url"]
    raise "No download URL for media #{media_id}: #{info}" if url.blank?

    content_type = info["mime_type"].to_s.split(";").first.presence || "application/octet-stream"
    filename = media["filename"].presence || "#{message.message_type}-#{media_id}#{extension_for(content_type)}"

    io = download_media(url)
    begin
      message.file.attach(io: io, filename: filename, content_type: content_type)
    ensure
      io.close! if io.respond_to?(:close!)
    end
    message.touch
  end

  private

  # Media URLs from Meta expire ~5 minutes after this call, so download right away.
  def fetch_media_info(media_id)
    uri = URI("https://graph.facebook.com/v25.0/#{media_id}")
    response = get_with_token(uri)
    raise "Media info request failed (HTTP #{response.code}): #{response.body.to_s.truncate(200)}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  # Streams the body into a Tempfile so large documents/videos don't sit in memory.
  def download_media(url, redirects_left = 3)
    uri = URI(url)
    raise "Refusing non-HTTPS media URL: #{uri.host}" unless uri.is_a?(URI::HTTPS)

    file = Tempfile.new("wa-media", binmode: true)
    redirect_to = nil
    get_with_token(uri) do |response|
      if response.is_a?(Net::HTTPRedirection)
        redirect_to = URI.join(uri, response["location"]).to_s
      elsif response.is_a?(Net::HTTPSuccess)
        response.read_body { |chunk| file.write(chunk) }
      else
        raise "Media download failed (HTTP #{response.code})"
      end
    end

    if redirect_to
      file.close!
      raise "Too many redirects downloading media" unless redirects_left.positive?
      return download_media(redirect_to, redirects_left - 1)
    end

    file.rewind
    file
  rescue StandardError
    file&.close!
    raise
  end

  META_HOSTS = %w[facebook.com fbsbx.com fbcdn.net whatsapp.net].freeze

  # Only send the Meta access token to Meta-owned hosts, never to a redirect target elsewhere.
  def get_with_token(uri, &block)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ENV["META_ACCESS_TOKEN"]}" if meta_host?(uri.host)
    http.request(request, &block)
  end

  def meta_host?(host)
    host = host.to_s.downcase
    META_HOSTS.any? { |domain| host == domain || host.end_with?(".#{domain}") }
  end

  def extension_for(content_type)
    Rack::Mime::MIME_TYPES.key(content_type) || ""
  end
end
