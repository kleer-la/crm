require "test_helper"

class ProposalCallbackLoggingTest < ActiveSupport::TestCase
  setup do
    @customer = create(:customer, :with_contact)
    @user = create(:user)
    @proposal = create(:proposal, :draft, linkable: @customer, responsible_consultant: @user)
  end

  test "proposal creation auto-logs system event" do
    proposal = create(:proposal, linkable: @customer)
    log = proposal.activity_logs.find_by(entry_type: :system)
    assert log.present?
    assert_includes log.content, "Proposal created"
  end

  test "proposal status change auto-logs system event" do
    assert_difference "ActivityLog.count", 1 do
      @proposal.update!(status: :sent)
    end

    log = ActivityLog.last
    assert_equal "system", log.entry_type
    assert_includes log.content, "Status changed"
    assert_includes log.content, "sent"
  end

  test "proposal status change from sent to under_review logs" do
    @proposal.update!(status: :sent)
    initial_count = @proposal.activity_logs.count

    @proposal.update!(status: :under_review)
    assert_equal initial_count + 1, @proposal.activity_logs.count

    log = @proposal.activity_logs.last
    assert_includes log.content, "under_review"
  end

  test "proposal responsible consultant change auto-logs" do
    new_user = create(:user)

    assert_difference "ActivityLog.count", 1 do
      @proposal.update!(responsible_consultant: new_user)
    end

    log = ActivityLog.last
    assert_equal "system", log.entry_type
    assert_includes log.content, "Responsible consultant changed"
  end

  test "proposal document url addition auto-logs" do
    assert_difference "ActivityLog.count", 1 do
      @proposal.update!(current_document_url: "https://docs.google.com/document/d/1234567890/edit")
    end

    log = ActivityLog.last
    assert_equal "system", log.entry_type
    assert_includes log.content, "Document link added"
    assert_includes log.content, "https://docs.google.com"
  end

  test "proposal document url update auto-logs" do
    @proposal.update!(current_document_url: "https://docs.google.com/document/d/old/edit")
    initial_count = @proposal.activity_logs.count

    @proposal.update!(current_document_url: "https://docs.google.com/document/d/new/edit")
    assert_equal initial_count + 1, @proposal.activity_logs.count

    log = @proposal.activity_logs.last
    assert_includes log.content, "Document link updated"
  end

  test "proposal document url removal auto-logs" do
    @proposal.update!(current_document_url: "https://docs.google.com/document/d/123/edit")
    initial_count = @proposal.activity_logs.count

    @proposal.update!(current_document_url: "")
    assert_equal initial_count + 1, @proposal.activity_logs.count

    log = @proposal.activity_logs.last
    assert_includes log.content, "Document link removed"
  end

  test "marking proposal as won updates customer revenue" do
    @customer.recalculate_total_revenue!
    assert_equal 0, @customer.total_revenue

    @proposal.update!(status: :won, final_value: 50000, win_loss_reason: "Strong fit")

    assert_equal 50000, @customer.reload.total_revenue
  end

  test "marking proposal as lost does not add to customer revenue" do
    @proposal.update!(status: :lost, win_loss_reason: "Budget constraints")

    assert_equal 0, @customer.reload.total_revenue
  end

  test "changing won proposal final_value updates customer revenue" do
    @proposal.update!(status: :won, final_value: 30000, win_loss_reason: "Great fit")
    assert_equal 30000, @customer.reload.total_revenue

    @proposal.update!(final_value: 50000)
    assert_equal 50000, @customer.reload.total_revenue
  end
end
