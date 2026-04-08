require "test_helper"

class TouchpointsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  test "create touchpoint for prospect" do
    prospect = create(:prospect)

    assert_difference "ActivityLog.count", 1 do
      post touchpoints_path, params: {
        loggable_type: "Prospect",
        loggable_id: prospect.id,
        touchpoint_type: "call",
        content: "Discussed requirements"
      }
    end

    assert_redirected_to root_path
    log = ActivityLog.last
    assert_equal "touchpoint", log.entry_type
    assert_equal "call", log.touchpoint_type
    assert_equal "Discussed requirements", log.content
    assert_equal @user, log.user
  end

  test "create touchpoint for customer" do
    customer = create(:customer)

    post touchpoints_path, params: {
      loggable_type: "Customer",
      loggable_id: customer.id,
      touchpoint_type: "meeting",
      content: "Quarterly review"
    }

    assert_redirected_to root_path
    log = customer.activity_logs.where(entry_type: :touchpoint).last
    assert_equal "meeting", log.touchpoint_type
  end

  test "create touchpoint for proposal" do
    proposal = create(:proposal)

    post touchpoints_path, params: {
      loggable_type: "Proposal",
      loggable_id: proposal.id,
      touchpoint_type: "email",
      content: "Sent follow-up"
    }

    assert_redirected_to root_path
  end

  test "create touchpoint with invalid loggable redirects with alert" do
    post touchpoints_path, params: {
      loggable_type: "Prospect",
      loggable_id: 0,
      touchpoint_type: "call",
      content: "Test"
    }

    assert_redirected_to root_path
    assert_equal "Record not found.", flash[:alert]
  end

  test "create touchpoint with empty content redirects with error" do
    customer = create(:customer)

    assert_no_difference "ActivityLog.count" do
      post touchpoints_path, params: {
        loggable_type: "Customer",
        loggable_id: customer.id,
        touchpoint_type: "call",
        content: ""
      }
    end

    assert_redirected_to root_path
    assert flash[:alert].present?
  end

  test "create touchpoint with invalid type redirects with error" do
    customer = create(:customer)

    post touchpoints_path, params: {
      loggable_type: "Customer",
      loggable_id: customer.id,
      touchpoint_type: "",
      content: "Test"
    }

    assert_redirected_to root_path
    assert flash[:alert].present?
  end

  test "unauthenticated user cannot create touchpoint" do
    delete logout_path
    post touchpoints_path, params: {
      loggable_type: "Customer",
      loggable_id: 1,
      touchpoint_type: "call",
      content: "Test"
    }
    assert_redirected_to login_path
  end

  test "create touchpoint with past occurred_at date persists correctly" do
    proposal = create(:proposal)
    past_date = 10.days.ago.to_date

    post touchpoints_path, params: {
      loggable_type: "Proposal",
      loggable_id: proposal.id,
      touchpoint_type: "call",
      content: "Backdated call",
      occurred_at: past_date.to_s
    }

    assert_redirected_to root_path
    log = proposal.activity_logs.where(entry_type: :touchpoint).last
    assert_equal past_date, log.occurred_at.to_date
    assert_equal past_date, proposal.reload.last_activity_date
  end

  test "create touchpoint without occurred_at defaults to today" do
    prospect = create(:prospect)
    freeze_time do
      post touchpoints_path, params: {
        loggable_type: "Prospect",
        loggable_id: prospect.id,
        touchpoint_type: "call",
        content: "Call today"
      }
      log = ActivityLog.last
      assert_equal Date.current, log.occurred_at.to_date
    end
  end
end
