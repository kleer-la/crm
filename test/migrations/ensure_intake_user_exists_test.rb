require "test_helper"

class EnsureIntakeUserExistsTest < ActiveSupport::TestCase
  def setup
    User.find_by(email: "info@kleer.la")&.destroy!
  end

  test "creates the Intake user on a fresh database" do
    run_migration

    user = User.find_by(email: "info@kleer.la")
    assert user
    assert_equal "Intake", user.name
    assert_equal "consultant", user.role
    assert user.active
  end

  test "is idempotent — leaves exactly one user no matter how many times run" do
    run_migration
    run_migration

    assert_equal 1, User.where(email: "info@kleer.la").count
  end

  private

  def run_migration
    User.find_or_create_by!(email: "info@kleer.la") do |user|
      user.name = "Intake"
      user.role = :consultant
      user.active = true
    end
  end
end
