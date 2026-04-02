# Record the current deployment to the database on app boot.
# BUILD_INFO env var is set by Kamal during deploy (see .kamal/secrets).

Rails.application.config.after_initialize do
  next unless defined?(Rails::Server) || ENV["RECORD_DEPLOYMENT"] == "true"
  next unless Deployment.table_exists?

  Deployment.record_from_build_info
end
