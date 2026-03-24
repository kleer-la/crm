require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer)
    @task = create(:task, linkable: @customer, assigned_to: @user)
  end

  # Index
  test "index lists tasks" do
    get tasks_path
    assert_response :success
    assert_includes response.body, @task.title
  end

  test "index filters by status" do
    done_task = create(:task, linkable: @customer, assigned_to: @user, status: :done, title: "Done Task", completed_at: Time.current)
    get tasks_path(status: "done")
    assert_response :success
    assert_includes response.body, "Done Task"
    assert_not_includes response.body, @task.title
  end

  test "index filters by priority" do
    high_task = create(:task, linkable: @customer, assigned_to: @user, priority: :high, title: "High Priority Task")
    get tasks_path(priority: "high")
    assert_response :success
    assert_includes response.body, "High Priority Task"
  end

  test "index filters by search" do
    other = create(:task, linkable: @customer, assigned_to: @user, title: "Unrelated Task")
    get tasks_path(search: @task.title)
    assert_response :success
    assert_includes response.body, @task.title
    assert_not_includes response.body, "Unrelated Task"
  end

  test "index sorts by due_date" do
    early = create(:task, linkable: @customer, assigned_to: @user, title: "Early Task", due_date: 1.day.from_now)
    late = create(:task, linkable: @customer, assigned_to: @user, title: "Late Task", due_date: 30.days.from_now)
    get tasks_path(sort: "due_date", dir: "asc")
    assert_response :success
    early_pos = response.body.index("Early Task")
    late_pos = response.body.index("Late Task")
    assert early_pos < late_pos, "Early Task should appear before Late Task in ascending order"
  end

  test "index combines filter and sort" do
    create(:task, linkable: @customer, assigned_to: @user, priority: :high, title: "Zulu High", due_date: 30.days.from_now)
    create(:task, linkable: @customer, assigned_to: @user, priority: :high, title: "Alpha High", due_date: 1.day.from_now)
    create(:task, linkable: @customer, assigned_to: @user, priority: :low, title: "Low Excluded", due_date: 2.days.from_now)
    get tasks_path(priority: "high", sort: "due_date", dir: "asc")
    assert_response :success
    assert_includes response.body, "Alpha High"
    assert_includes response.body, "Zulu High"
    assert_not_includes response.body, "Low Excluded"
    assert response.body.index("Alpha High") < response.body.index("Zulu High")
  end

  test "index filters overdue only" do
    overdue_task = create(:task, :overdue, linkable: @customer, assigned_to: @user)
    get tasks_path(overdue: "1")
    assert_response :success
    assert_includes response.body, overdue_task.title
  end

  # Show
  test "show displays task" do
    get task_path(@task)
    assert_response :success
    assert_includes response.body, @task.title
  end

  # New
  test "new renders form" do
    get new_task_path
    assert_response :success
  end

  test "new pre-fills linkable from params" do
    get new_task_path(linkable_type: "Customer", linkable_id: @customer.id)
    assert_response :success
  end

  # Create
  test "create task" do
    assert_difference("Task.count", 1) do
      post tasks_path, params: { task: {
        title: "Follow up call",
        linkable_type: "Customer",
        linkable_id: @customer.id,
        assigned_to_id: @user.id,
        due_date: 5.days.from_now.to_date,
        priority: "high",
        notes: "Important task"
      } }
    end
    assert_redirected_to task_path(Task.last)
    assert_equal "Follow up call", Task.last.title
  end

  test "create task with invalid data renders new" do
    post tasks_path, params: { task: { title: "" } }
    assert_response :unprocessable_entity
  end

  # Edit
  test "edit renders form" do
    get edit_task_path(@task)
    assert_response :success
  end

  # Update
  test "update task" do
    patch task_path(@task), params: { task: { title: "Updated title" } }
    assert_redirected_to task_path(@task)
    assert_equal "Updated title", @task.reload.title
  end

  test "update with invalid data renders edit" do
    patch task_path(@task), params: { task: { title: "" } }
    assert_response :unprocessable_entity
  end

  # Destroy
  test "destroy task" do
    assert_difference("Task.count", -1) do
      delete task_path(@task)
    end
    assert_redirected_to tasks_path
  end

  # Mark Done
  test "mark_done sets status and completed_at" do
    patch mark_done_task_path(@task)
    assert_redirected_to task_path(@task)
    @task.reload
    assert @task.done?
    assert_not_nil @task.completed_at
  end

  # Cancel
  test "cancel with reason" do
    patch cancel_task_path(@task), params: { task: { cancellation_reason: "Budget cut" } }
    assert_redirected_to task_path(@task)
    @task.reload
    assert @task.cancelled?
    assert_equal "Budget cut", @task.cancellation_reason
  end

  test "cancel without reason redirects with alert" do
    patch cancel_task_path(@task), params: { task: { cancellation_reason: "" } }
    assert_redirected_to task_path(@task)
    assert_match(/cancellation/i, flash[:alert])
  end

  # Reassign
  test "reassign task" do
    other_user = create(:user)
    patch reassign_task_path(@task), params: { task: { assigned_to_id: other_user.id } }
    assert_redirected_to task_path(@task)
    assert_equal other_user, @task.reload.assigned_to
  end

  # Auth
  test "requires authentication" do
    delete logout_path
    get tasks_path
    assert_redirected_to login_path
  end

  # Task from linked records
  test "new task pre-fills from prospect" do
    prospect = create(:prospect)
    get new_task_path(linkable_type: "Prospect", linkable_id: prospect.id)
    assert_response :success
  end

  test "new task pre-fills from proposal" do
    proposal = create(:proposal, linkable: @customer)
    get new_task_path(linkable_type: "Proposal", linkable_id: proposal.id)
    assert_response :success
  end
end
