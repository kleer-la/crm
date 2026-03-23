require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "valid task" do
    task = build(:task)
    assert task.valid?
  end

  test "requires title" do
    task = build(:task, title: nil)
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "requires due_date" do
    task = build(:task, due_date: nil)
    assert_not task.valid?
    assert_includes task.errors[:due_date], "can't be blank"
  end

  test "due_date not in past on create" do
    task = build(:task, due_date: 1.day.ago.to_date)
    assert_not task.valid?
    assert task.errors[:due_date].any?
  end

  test "allows past due_date on update" do
    task = create(:task)
    task.due_date = 1.day.ago.to_date
    assert task.valid?
  end

  test "requires cancellation_reason when cancelled" do
    task = build(:task, status: :cancelled, cancellation_reason: nil)
    assert_not task.valid?
    assert_includes task.errors[:cancellation_reason], "can't be blank"
  end

  test "allows cancelled with reason" do
    task = build(:task, :cancelled)
    assert task.valid?
  end

  test "priority enum values" do
    assert_equal({ "low" => 0, "medium" => 1, "high" => 2 }, Task.priorities)
  end

  test "status enum values" do
    assert_equal({ "open" => 0, "in_progress" => 1, "done" => 2, "cancelled" => 3 }, Task.statuses)
  end

  test "scope overdue" do
    overdue = create(:task, :overdue)
    future = create(:task)

    assert_includes Task.overdue, overdue
    assert_not_includes Task.overdue, future
  end

  test "mark_done! sets status and completed_at" do
    task = create(:task)
    assert_nil task.completed_at

    task.mark_done!
    task.reload

    assert task.done?
    assert_not_nil task.completed_at
  end

  test "cancel! sets status and cancellation_reason" do
    task = create(:task)

    task.cancel!("No longer needed")
    task.reload

    assert task.cancelled?
    assert_equal "No longer needed", task.cancellation_reason
  end

  test "cancel! without reason raises validation error" do
    task = create(:task)

    assert_raises(ActiveRecord::RecordInvalid) do
      task.cancel!("")
    end
    assert task.reload.open?
  end

  test "set_completed_at does not overwrite existing timestamp" do
    task = create(:task)
    original_time = 2.days.ago
    task.update_column(:completed_at, original_time)

    task.update!(status: :done)
    assert_in_delta original_time.to_f, task.reload.completed_at.to_f, 1.0
  end

  test "polymorphic linkable to prospect" do
    prospect = create(:prospect)
    task = create(:task, linkable: prospect)
    assert_equal "Prospect", task.linkable_type
    assert_equal prospect, task.linkable
  end

  test "polymorphic linkable to customer" do
    customer = create(:customer)
    task = create(:task, linkable: customer)
    assert_equal "Customer", task.linkable_type
  end

  test "polymorphic linkable to proposal" do
    proposal = create(:proposal)
    task = create(:task, linkable: proposal)
    assert_equal "Proposal", task.linkable_type
    assert_equal proposal, task.linkable
  end

  test "logs creation on task" do
    task = create(:task)
    assert task.activity_logs.exists?(entry_type: :system, content: "Task created: #{task.title}")
  end

  test "logs creation on linked record" do
    customer = create(:customer)
    task = create(:task, linkable: customer)
    assert customer.activity_logs.exists?(content: "Task added: #{task.title}")
  end

  test "logs status change" do
    task = create(:task)
    task.update!(status: :in_progress)
    assert task.activity_logs.exists?(content: "Status changed from open to in_progress")
  end

  test "logs reassignment on task and linked record" do
    user1 = create(:user)
    user2 = create(:user)
    customer = create(:customer)
    task = create(:task, assigned_to: user1, linkable: customer)

    task.update!(assigned_to: user2)
    assert task.activity_logs.exists?(content: "Reassigned from #{user1.name} to #{user2.name}")
    assert customer.activity_logs.exists?(content: "Task '#{task.title}' reassigned to #{user2.name}")
  end
end
