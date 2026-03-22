require "test_helper"

class ConsultantAssignmentTest < ActiveSupport::TestCase
  test "valid assignment" do
    user = create(:user)
    prospect = create(:prospect)
    ca = ConsultantAssignment.new(user: user, assignable: prospect)
    assert ca.valid?
  end

  test "unique per user and assignable" do
    user = create(:user)
    prospect = create(:prospect)
    ConsultantAssignment.create!(user: user, assignable: prospect)
    ca = ConsultantAssignment.new(user: user, assignable: prospect)
    assert_not ca.valid?
  end
end
