require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in(@admin)
  end

  test "edit renders settings" do
    get edit_admin_settings_path
    assert_response :success
    assert_includes response.body, "Send welcome message on Instagram"
  end

  test "update enables the instagram welcome" do
    patch admin_settings_path, params: { ig_welcome_enabled: "1" }
    assert_redirected_to edit_admin_settings_path
    assert Setting.ig_welcome_enabled?
  end

  test "update disables the instagram welcome when unchecked" do
    Setting.set("ig_welcome_enabled", "true")
    patch admin_settings_path, params: {}
    assert_not Setting.ig_welcome_enabled?
  end

  test "non-admin cannot access" do
    sign_in(create(:user))
    get edit_admin_settings_path
    assert_redirected_to root_path
  end
end
