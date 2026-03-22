require "test_helper"

class ProspectConversionFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @prospect = create(:prospect, :qualified, responsible_consultant: @user)
  end

  test "converted prospect is read-only and cannot be edited" do
    old_name = @prospect.company_name
    ConvertProspectService.new(@prospect, @user).call

    # Attempting to edit should prevent the action (redirect or show error)
    patch prospect_path(@prospect), params: {
      prospect: { company_name: "New Name" }
    }

    # Company name should not have changed
    assert_equal old_name, @prospect.reload.company_name
  end

  test "converting prospect creates activity log entry" do
    # Note: Conversion creates at least 1 log entry (may be more due to status change logging)
    initial_count = ActivityLog.count
    ConvertProspectService.new(@prospect, @user).call
    final_count = ActivityLog.count

    assert final_count > initial_count

    log = ActivityLog.where(loggable: @prospect).where(entry_type: :system).last
    assert_equal "system", log.entry_type
    assert_includes log.content, "Converted"
  end

  test "converting prospect shows customer reference on prospect show page" do
    customer = ConvertProspectService.new(@prospect, @user).call

    get prospect_path(@prospect)
    assert_response :success
    assert_includes response.body, customer.company_name
  end

  test "proposals relinked during conversion" do
    proposal1 = create(:proposal, :draft, linkable: @prospect, title: "First Proposal")
    proposal2 = create(:proposal, :sent, linkable: @prospect, title: "Second Proposal")

    customer = ConvertProspectService.new(@prospect, @user).call

    assert_equal customer, proposal1.reload.linkable
    assert_equal customer, proposal2.reload.linkable
  end

  test "cannot convert disqualified prospect" do
    disqualified = create(:prospect, :disqualified, responsible_consultant: @user)

    error = assert_raises(ConvertProspectService::ConversionError) do
      ConvertProspectService.new(disqualified, @user).call
    end

    assert_includes error.message, "disqualified"
  end

  test "converted prospect has converted_customer reference" do
    customer = ConvertProspectService.new(@prospect, @user).call

    assert_equal customer, @prospect.reload.converted_customer
  end
end
