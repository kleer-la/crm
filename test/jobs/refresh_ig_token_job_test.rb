require "test_helper"

class RefreshIgTokenJobTest < ActiveSupport::TestCase
  setup do
    @job = RefreshIgTokenJob.new
  end

  test "stores the refreshed token" do
    Setting.set("ig_access_token", "old_token")
    @job.define_singleton_method(:refresh_request) do |token|
      raise "refreshed with wrong token" unless token == "old_token"
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, { access_token: "new_token", token_type: "bearer", expires_in: 5_184_000 }.to_json)
      response
    end

    @job.perform

    assert_equal "new_token", Setting.get("ig_access_token")
  end

  test "raises when refresh fails so the failure is visible" do
    Setting.set("ig_access_token", "old_token")
    @job.define_singleton_method(:refresh_request) do |_token|
      response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, { error: { message: "expired" } }.to_json)
      response
    end

    assert_raises(RuntimeError) { @job.perform }
    assert_equal "old_token", Setting.get("ig_access_token")
  end

  test "skips quietly when no token is configured" do
    @job.define_singleton_method(:refresh_request) { |_token| raise "should not be called" }

    @job.perform

    assert_nil Setting.get("ig_access_token")
  end
end
