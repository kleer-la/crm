require "test_helper"

class DeploymentTest < ActiveSupport::TestCase
  test "valid deployment" do
    deployment = build(:deployment)
    assert deployment.valid?
  end

  test "requires deployed_at" do
    deployment = build(:deployment, deployed_at: nil)
    assert_not deployment.valid?
    assert_includes deployment.errors[:deployed_at], "can't be blank"
  end

  test "requires commit_sha" do
    deployment = build(:deployment, commit_sha: nil)
    assert_not deployment.valid?
    assert_includes deployment.errors[:commit_sha], "can't be blank"
  end

  test "deployed_at must be unique" do
    existing = create(:deployment)
    duplicate = build(:deployment, deployed_at: existing.deployed_at)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:deployed_at], "has already been taken"
  end

  test "recent scope orders by deployed_at desc" do
    old = create(:deployment, deployed_at: 2.hours.ago)
    new_deploy = create(:deployment, deployed_at: 1.hour.ago)
    assert_equal [ new_deploy, old ], Deployment.recent.to_a
  end

  test "record_from_build_info creates deployment from valid JSON" do
    build_info = {
      version: "abc123d",
      commit_sha: "abc123d1234567890abcdef1234567890abcdef12",
      commit_url: "https://github.com/kleer-la/crm/commit/abc123d",
      commit_message: "Fix bug",
      author: "Dev <dev@example.com>",
      branch: "main",
      deployed_at: Time.current.iso8601,
      deployed_by: "carlos",
      environment: "production"
    }.to_json

    ENV["BUILD_INFO"] = build_info
    assert_difference "Deployment.count", 1 do
      Deployment.record_from_build_info
    end
  ensure
    ENV.delete("BUILD_INFO")
  end

  test "record_from_build_info skips duplicate deployed_at" do
    deployed_time = "2026-03-26T10:00:00Z"
    existing = create(:deployment, deployed_at: Time.zone.parse(deployed_time))
    build_info = {
      version: "newver",
      commit_sha: "newsha1234567890abcdef1234567890abcdef1234",
      deployed_at: deployed_time,
      deployed_by: "carlos",
      environment: "production"
    }.to_json

    ENV["BUILD_INFO"] = build_info
    assert_no_difference "Deployment.count" do
      Deployment.record_from_build_info
    end
  ensure
    ENV.delete("BUILD_INFO")
  end

  test "record_from_build_info does nothing when BUILD_INFO missing" do
    ENV.delete("BUILD_INFO")
    assert_no_difference "Deployment.count" do
      Deployment.record_from_build_info
    end
  end

  test "record_from_build_info handles invalid JSON" do
    ENV["BUILD_INFO"] = "not valid json"
    assert_no_difference "Deployment.count" do
      Deployment.record_from_build_info
    end
  ensure
    ENV.delete("BUILD_INFO")
  end
end
