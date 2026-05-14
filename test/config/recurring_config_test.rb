require "test_helper"

class RecurringConfigTest < ActiveSupport::TestCase
  test "conversation_auto_disconnect is configured for all environments" do
    config = YAML.safe_load_file(Rails.root.join("config/recurring.yml"), aliases: true)

    %w[development test production].each do |env|
      entry = config.dig(env, "conversation_auto_disconnect")
      assert entry, "Missing conversation_auto_disconnect in #{env}"
      assert_equal "ConversationAutoDisconnectJob", entry["class"]
      assert_equal "every hour", entry["schedule"]
      assert_equal "default", entry["queue"]
    end
  end
end
