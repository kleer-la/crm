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
end
