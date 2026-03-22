require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = build(:user)
    assert user.valid?
  end

  test "requires name" do
    user = build(:user, name: nil)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "requires email" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    create(:user, email: "dup@example.com")
    user = build(:user, email: "dup@example.com")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "role enum values" do
    assert_equal({ "pending" => 0, "consultant" => 1, "admin" => 2 }, User.roles)
  end

  test "scope active excludes deactivated" do
    active_user = create(:user)
    deactivated = create(:user, :deactivated)

    assert_includes User.active, active_user
    assert_not_includes User.active, deactivated
  end

  test "scope assignable excludes pending and deactivated" do
    consultant = create(:user)
    admin = create(:user, :admin)
    pending = create(:user, :pending)
    deactivated = create(:user, :deactivated)

    assignable = User.assignable
    assert_includes assignable, consultant
    assert_includes assignable, admin
    assert_not_includes assignable, pending
    assert_not_includes assignable, deactivated
  end

  test "display_name shows deactivated prefix" do
    user = build(:user, name: "Alice")
    assert_equal "Alice", user.display_name

    user.active = false
    assert_equal "(Deactivated) Alice", user.display_name
  end
end
