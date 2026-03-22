require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "user_display_name returns name for active user" do
    user = build(:user, name: "Alice")
    assert_equal "Alice", user_display_name(user)
  end

  test "user_display_name returns Unknown for nil" do
    assert_equal "Unknown", user_display_name(nil)
  end

  test "role_badge renders admin badge" do
    user = build(:user, :admin)
    badge = role_badge(user)
    assert_includes badge, "Admin"
    assert_includes badge, "bg-purple-100"
  end

  test "role_badge renders consultant badge" do
    user = build(:user, role: :consultant)
    badge = role_badge(user)
    assert_includes badge, "Consultant"
    assert_includes badge, "bg-blue-100"
  end

  test "role_badge renders pending badge" do
    user = build(:user, :pending)
    badge = role_badge(user)
    assert_includes badge, "Pending"
    assert_includes badge, "bg-yellow-100"
  end

  test "status_badge shows Deactivated when not active" do
    badge = status_badge("active", active: false)
    assert_includes badge, "Deactivated"
    assert_includes badge, "bg-red-100"
  end

  test "status_badge shows titleized status when active" do
    badge = status_badge("new_prospect", active: true)
    assert_includes badge, "New Prospect"
  end

  test "currency formats amount" do
    assert_equal "$1,234.56", currency(1234.56)
  end

  test "currency handles nil" do
    assert_equal "$0.00", currency(nil)
  end

  test "currency handles zero" do
    assert_equal "$0.00", currency(0)
  end
end
