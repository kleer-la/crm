class Deployment < ApplicationRecord
  validates :deployed_at, presence: true, uniqueness: true
  validates :commit_sha, presence: true

  scope :recent, -> { order(deployed_at: :desc) }

  # Record a deployment from BUILD_INFO env var (called on app boot)
  def self.record_from_build_info
    build_info = ENV.fetch("BUILD_INFO", nil)
    return if build_info.blank?

    begin
      info = JSON.parse(build_info)
      deployed_at = Time.zone.parse(info["deployed_at"])

      return if exists?(deployed_at: deployed_at)

      create!(
        version: info["version"],
        commit_sha: info["commit_sha"],
        commit_url: info["commit_url"],
        commit_message: info["commit_message"],
        author: info["author"],
        branch: info["branch"],
        environment: info["environment"],
        deployed_at: deployed_at,
        deployed_by: info["deployed_by"]
      )

      Rails.logger.info "[Deployment] Recorded deployment #{info['version']} at #{deployed_at}"
    rescue JSON::ParserError => e
      Rails.logger.error "[Deployment] Failed to parse BUILD_INFO: #{e.message}"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[Deployment] Failed to record deployment: #{e.message}"
    end
  end
end
