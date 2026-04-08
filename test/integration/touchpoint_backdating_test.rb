require "test_helper"

class TouchpointBackdatingTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer, :with_contact)
    @proposal = create(:proposal, linkable: @customer, responsible_consultant: @user)
  end

  test "backdated touchpoint appears in correct timeline position" do
    # Log a recent touchpoint
    recent_date = 2.days.ago.to_date
    post touchpoints_path, params: {
      loggable_type: "Proposal",
      loggable_id: @proposal.id,
      touchpoint_type: "call",
      content: "Recent call",
      occurred_at: recent_date.to_s
    }

    # Log an older backdated touchpoint
    old_date = 10.days.ago.to_date
    post touchpoints_path, params: {
      loggable_type: "Proposal",
      loggable_id: @proposal.id,
      touchpoint_type: "email",
      content: "Older email",
      occurred_at: old_date.to_s
    }

    logs = @proposal.activity_logs.where(entry_type: :touchpoint).order(occurred_at: :desc)
    assert_equal 2, logs.count
    assert_equal recent_date, logs.first.occurred_at.to_date
    assert_equal old_date, logs.last.occurred_at.to_date
  end

  test "touchpoint on proposal updates last_activity_date to occurred_at" do
    past_date = 7.days.ago.to_date

    post touchpoints_path, params: {
      loggable_type: "Proposal",
      loggable_id: @proposal.id,
      touchpoint_type: "meeting",
      content: "Backdated meeting",
      occurred_at: past_date.to_s
    }

    assert_equal past_date, @proposal.reload.last_activity_date
  end

  test "backdated touchpoint does not mark proposal as stale" do
    # Log a touchpoint within STALE_DAYS using occurred_at
    recent_occurred = (Proposal::STALE_DAYS - 5).days.ago.to_date

    post touchpoints_path, params: {
      loggable_type: "Proposal",
      loggable_id: @proposal.id,
      touchpoint_type: "call",
      content: "Recent-ish call",
      occurred_at: recent_occurred.to_s
    }

    assert_not_includes Proposal.stale, @proposal
  end
end
