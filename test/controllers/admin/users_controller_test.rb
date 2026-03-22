require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in(@admin)
  end

  test "index shows user lists" do
    pending_user = create(:user, :pending)
    consultant = create(:user)
    deactivated = create(:user, :deactivated)

    get admin_users_path
    assert_response :success
    assert_includes response.body, pending_user.name
    assert_includes response.body, consultant.name
    assert_includes response.body, deactivated.name
  end

  test "assign_role changes user role" do
    pending_user = create(:user, :pending)

    patch assign_role_admin_user_path(pending_user), params: { role: "consultant" }
    assert_redirected_to admin_users_path
    assert_equal "consultant", pending_user.reload.role
  end

  test "assign_role to admin" do
    user = create(:user)

    patch assign_role_admin_user_path(user), params: { role: "admin" }
    assert_redirected_to admin_users_path
    assert_equal "admin", user.reload.role
  end

  test "deactivate user" do
    user = create(:user)

    patch deactivate_admin_user_path(user)
    assert_redirected_to admin_users_path
    assert_not user.reload.active?
  end

  test "reactivate user" do
    user = create(:user, :deactivated)

    patch reactivate_admin_user_path(user)
    assert_redirected_to admin_users_path
    assert user.reload.active?
  end

  test "non-admin cannot access admin users" do
    consultant = create(:user)
    sign_in(consultant)

    get admin_users_path
    assert_redirected_to root_path
  end

  test "unauthenticated user cannot access admin users" do
    delete logout_path
    get admin_users_path
    assert_redirected_to login_path
  end
end
