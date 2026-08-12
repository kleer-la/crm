# URL helpers need a host when rendering outside a request — Turbo Stream
# broadcast jobs being the main case. Without one, Active Storage URLs in
# broadcast partials (e.g. media attachments) point at the renderer fallback
# host "example.org".
Rails.application.routes.default_url_options = {
  host: ENV.fetch("APP_HOST") { Rails.env.production? ? "crm.kleer.la" : "localhost:3000" },
  protocol: Rails.env.production? ? "https" : "http"
}
