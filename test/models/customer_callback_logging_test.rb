require "test_helper"

class CustomerCallbackLoggingTest < ActiveSupport::TestCase
  setup do
    @customer = create(:customer, :with_contact)
  end

  test "customer creation auto-logs system event" do
    customer = create(:customer)
    log = customer.activity_logs.find_by(entry_type: :system)
    assert log.present?
    assert_includes log.content, "Customer created"
  end

  test "customer status change auto-logs system event" do
    assert_difference "ActivityLog.count", 1 do
      @customer.update!(status: :at_risk)
    end

    log = ActivityLog.last
    assert_equal "system", log.entry_type
    assert_includes log.content, "Status changed"
  end

  test "responsible consultant change auto-logs" do
    new_user = create(:user)

    assert_difference "ActivityLog.count", 1 do
      @customer.update!(responsible_consultant: new_user)
    end

    log = ActivityLog.last
    assert_equal "system", log.entry_type
    assert_includes log.content, "Responsible consultant changed"
  end

  test "last_activity_date updates on touchpoint" do
    old_date = @customer.last_activity_date
    travel 1.day

    @customer.log_touchpoint(touchpoint_type: :email, content: "Sent proposal", user: create(:user))
    new_date = @customer.reload.last_activity_date

    assert new_date > old_date
  end

  test "total_revenue updates when proposal marked as won" do
    assert_equal 0, @customer.total_revenue

    proposal = create(:proposal, :draft, linkable: @customer, estimated_value: 50000)
    proposal.update!(status: :won, estimated_value: 50000, win_loss_reason: "Strong fit")

    assert_equal 50000, @customer.reload.total_revenue
  end

  test "total_revenue includes multiple won proposals" do
    create(:proposal, :won, linkable: @customer, estimated_value: 25000)
    create(:proposal, :won, linkable: @customer, estimated_value: 35000)
    create(:proposal, :lost, linkable: @customer, estimated_value: 10000)

    @customer.recalculate_total_revenue!
    assert_equal 60000, @customer.reload.total_revenue
  end

  test "total_revenue recalculates when won proposal reverts to draft" do
    proposal = create(:proposal, :won, linkable: @customer, estimated_value: 50000)
    @customer.recalculate_total_revenue!
    assert_equal 50000, @customer.total_revenue

    proposal.update!(status: :draft)
    @customer.recalculate_total_revenue!
    assert_equal 0, @customer.total_revenue
  end
end
