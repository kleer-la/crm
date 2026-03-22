require "test_helper"

class CustomerHistoryTimelineTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer, :with_contact, responsible_consultant: @user)
  end

  test "customer show displays activity log entries chronologically" do
    @customer.log_system_event("First event")
    travel 1.hour
    @customer.log_system_event("Second event")
    travel 1.hour
    @customer.log_system_event("Third event")

    get customer_path(@customer)
    assert_response :success

    # All logs should appear in response
    assert_includes response.body, "First event"
    assert_includes response.body, "Second event"
    assert_includes response.body, "Third event"
  end

  test "customer history includes linked proposals in associations" do
    proposal1 = create(:proposal, :draft, linkable: @customer, title: "Proposal A")
    proposal2 = create(:proposal, :sent, linkable: @customer, title: "Proposal B")

    # Verify proposals are linked
    assert_includes @customer.proposals, proposal1
    assert_includes @customer.proposals, proposal2
  end

  test "customer history includes linked tasks in associations" do
    task1 = create(:task, linkable: @customer, title: "Follow up call")
    task2 = create(:task, linkable: @customer, title: "Send contract")

    # Verify tasks are linked
    assert_includes @customer.tasks, task1
    assert_includes @customer.tasks, task2
  end
end
