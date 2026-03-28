require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "user_display_name returns name for active user" do
    user = build(:user, name: "Alice")
    assert_equal "Alice", user_display_name(user)
  end

  test "user_display_name returns Unknown for nil" do
    assert_equal "Unknown", user_display_name(nil)
  end

  # role_badge tests
  test "role_badge renders admin badge with violet" do
    user = build(:user, :admin)
    badge = role_badge(user)
    assert_includes badge, "Admin"
    assert_includes badge, "bg-violet-100"
    assert_includes badge, "text-violet-700"
  end

  test "role_badge renders consultant badge with indigo" do
    user = build(:user, role: :consultant)
    badge = role_badge(user)
    assert_includes badge, "Consultant"
    assert_includes badge, "bg-indigo-100"
    assert_includes badge, "text-indigo-700"
  end

  test "role_badge renders pending badge with amber" do
    user = build(:user, :pending)
    badge = role_badge(user)
    assert_includes badge, "Pending"
    assert_includes badge, "bg-amber-100"
    assert_includes badge, "text-amber-700"
  end

  # status_badge — inactive flag
  test "status_badge shows Deactivated when not active" do
    badge = status_badge("active", active: false)
    assert_includes badge, "Deactivated"
    assert_includes badge, "bg-red-100"
  end

  # status_badge — prospect statuses
  test "status_badge new_prospect renders sky blue" do
    badge = status_badge("new_prospect")
    assert_includes badge, "New prospect"
    assert_includes badge, "bg-sky-100"
    assert_includes badge, "text-sky-700"
  end

  test "status_badge contacted renders sky blue" do
    badge = status_badge("contacted")
    assert_includes badge, "bg-sky-100"
  end

  test "status_badge qualified renders green" do
    badge = status_badge("qualified")
    assert_includes badge, "bg-green-100"
    assert_includes badge, "text-green-700"
  end

  test "status_badge disqualified renders red" do
    badge = status_badge("disqualified")
    assert_includes badge, "bg-red-100"
    assert_includes badge, "text-red-700"
  end

  test "status_badge converted renders violet" do
    badge = status_badge("converted")
    assert_includes badge, "bg-violet-100"
    assert_includes badge, "text-violet-700"
  end

  # status_badge — customer statuses
  test "status_badge active renders green" do
    badge = status_badge("active")
    assert_includes badge, "bg-green-100"
    assert_includes badge, "text-green-700"
  end

  test "status_badge inactive renders slate" do
    badge = status_badge("inactive")
    assert_includes badge, "bg-slate-100"
    assert_includes badge, "text-slate-600"
  end

  test "status_badge at_risk renders amber" do
    badge = status_badge("at_risk")
    assert_includes badge, "bg-amber-100"
    assert_includes badge, "text-amber-700"
  end

  # status_badge — proposal statuses
  test "status_badge draft renders slate" do
    badge = status_badge("draft")
    assert_includes badge, "bg-slate-100"
  end

  test "status_badge sent renders sky blue" do
    badge = status_badge("sent")
    assert_includes badge, "bg-sky-100"
  end

  test "status_badge won renders green" do
    badge = status_badge("won")
    assert_includes badge, "bg-green-100"
    assert_includes badge, "text-green-700"
  end

  test "status_badge lost renders red" do
    badge = status_badge("lost")
    assert_includes badge, "bg-red-100"
    assert_includes badge, "text-red-700"
  end

  # status_badge — task statuses
  test "status_badge open renders amber" do
    badge = status_badge("open")
    assert_includes badge, "bg-amber-100"
    assert_includes badge, "text-amber-700"
  end

  test "status_badge done renders green" do
    badge = status_badge("done")
    assert_includes badge, "bg-green-100"
  end

  # status_badge — fallback
  test "status_badge unknown status renders neutral slate" do
    badge = status_badge("something_unknown")
    assert_includes badge, "bg-slate-100"
    assert_includes badge, "text-slate-600"
  end

  # currency helper
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
