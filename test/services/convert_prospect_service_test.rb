require "test_helper"

class ConvertProspectServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @prospect = create(:prospect, responsible_consultant: @user)
  end

  test "converts prospect to customer" do
    customer = ConvertProspectService.new(@prospect, @user).call

    assert customer.persisted?
    assert_equal @prospect.company_name, customer.company_name
    assert_equal @prospect.responsible_consultant, customer.responsible_consultant
    assert_equal "active", customer.status
    assert_equal "converted", @prospect.reload.status
    assert_equal customer, @prospect.converted_customer
  end

  test "relinks proposals to new customer" do
    proposal = create(:proposal, linkable: @prospect)

    customer = ConvertProspectService.new(@prospect, @user).call

    assert_equal customer, proposal.reload.linkable
  end

  test "relinks tasks to new customer" do
    task = create(:task, linkable: @prospect)

    customer = ConvertProspectService.new(@prospect, @user).call

    assert_equal customer, task.reload.linkable
  end

  test "raises error for already converted prospect" do
    customer = create(:customer)
    @prospect.update!(status: :converted, converted_customer: customer)

    error = assert_raises(ConvertProspectService::ConversionError) do
      ConvertProspectService.new(@prospect, @user).call
    end

    assert_equal "Prospect has already been converted", error.message
  end

  test "raises error for disqualified prospect" do
    @prospect.update!(status: :disqualified, disqualification_reason: "Not a fit")

    error = assert_raises(ConvertProspectService::ConversionError) do
      ConvertProspectService.new(@prospect, @user).call
    end

    assert_equal "Cannot convert a disqualified prospect", error.message
  end

  test "conversion is transactional - rolls back on failure" do
    # Create a customer then set its name to match the prospect, bypassing validation
    existing = create(:customer)
    existing.update_column(:company_name, @prospect.company_name)

    assert_raises(ActiveRecord::RecordInvalid) do
      ConvertProspectService.new(@prospect, @user).call
    end

    # Transaction rolled back, so prospect should NOT be converted
    assert_not @prospect.reload.converted?
  end
end
