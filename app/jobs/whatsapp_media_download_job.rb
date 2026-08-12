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

    message.file.attach(
      io: StringIO.new(download_media(url)),
      filename: filename,
      content_type: content_type
    )
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

  def download_media(url, redirects_left = 3)
    response = get_with_token(URI(url))

    if response.is_a?(Net::HTTPRedirection) && redirects_left.positive?
      return download_media(response["location"], redirects_left - 1)
    end
    raise "Media download failed (HTTP #{response.code})" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def get_with_token(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ENV["META_ACCESS_TOKEN"]}"
    http.request(request)
  end

  def extension_for(content_type)
    Rack::Mime::MIME_TYPES.key(content_type) || ""
  end
end
