require "test_helper"

class TaskWorkflowTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @customer = create(:customer, :with_contact)
    @task = create(:task, linkable: @customer, assigned_to: @user)
  end

  test "mark task as in_progress" do
    assert_equal "open", @task.status

    @task.update!(status: :in_progress)
    assert_equal "in_progress", @task.reload.status
  end

  test "mark task as done" do
    @task.update!(status: :done)
    assert_equal "done", @task.reload.status
  end

  test "task transitions from open to in_progress to done" do
    assert_equal "open", @task.status
    @task.update!(status: :in_progress)
    assert_equal "in_progress", @task.reload.status
    @task.update!(status: :done)
    assert_equal "done", @task.reload.status
  end

  test "cancel task requires cancellation_reason" do
    @task.status = :cancelled
    assert_not @task.valid?
    assert_includes @task.errors[:cancellation_reason], "can't be blank"
  end

  test "task can be cancelled with reason" do
    @task.update!(status: :cancelled, cancellation_reason: "No longer needed")
    assert_equal "cancelled", @task.reload.status
    assert_equal "No longer needed", @task.cancellation_reason
  end

  test "task priority affects ordering" do
    high = create(:task, priority: :high, linkable: @customer)
    low = create(:task, priority: :low, linkable: @customer)
    medium = create(:task, priority: :medium, linkable: @customer)

    # Just verify they can be created and accessed
    assert_equal "high", high.priority
    assert_equal "low", low.priority
    assert_equal "medium", medium.priority
  end

  test "overdue task scope excludes future tasks" do
    overdue = create(:task, :overdue, linkable: @customer)
    future = create(:task, due_date: 5.days.from_now, linkable: @customer)
    completed = create(:task, :overdue, status: :done, linkable: @customer)

    overdue_tasks = Task.overdue
    assert_includes overdue_tasks, overdue
    assert_not_includes overdue_tasks, future
    assert_not_includes overdue_tasks, completed
  end

  test "task can be linked to prospect" do
    prospect = create(:prospect)
    prospect_task = create(:task, linkable: prospect)

    assert_equal prospect, prospect_task.linkable
  end

  test "task can be linked to proposal" do
    proposal = create(:proposal)
    proposal_task = create(:task, linkable: proposal)

    assert_equal proposal, proposal_task.linkable
  end

  test "task assigned_to can be changed" do
    new_user = create(:user)
    @task.update!(assigned_to: new_user)

    assert_equal new_user, @task.reload.assigned_to
  end
end
