require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "set stores and get retrieves a value" do
    Setting.set("some_key", "some_value")
    assert_equal "some_value", Setting.get("some_key")
  end

  test "set overwrites an existing value" do
    Setting.set("some_key", "old")
    Setting.set("some_key", "new")
    assert_equal "new", Setting.get("some_key")
    assert_equal 1, Setting.where(key: "some_key").count
  end

  test "get returns nil for unknown key" do
    assert_nil Setting.get("missing")
  end

  test "ig_access_token prefers the stored value over ENV" do
    ENV["META_IG_ACCESS_TOKEN"] = "env_token"
    Setting.set("ig_access_token", "db_token")
    assert_equal "db_token", Setting.ig_access_token
  ensure
    ENV.delete("META_IG_ACCESS_TOKEN")
  end

  test "ig_access_token falls back to ENV when not stored" do
    ENV["META_IG_ACCESS_TOKEN"] = "env_token"
    assert_equal "env_token", Setting.ig_access_token
  ensure
    ENV.delete("META_IG_ACCESS_TOKEN")
  end
end
