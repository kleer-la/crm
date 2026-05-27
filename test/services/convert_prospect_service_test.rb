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

  test "conversion pre-populates customer data and sets date_became_customer to today" do
    @prospect.update!(industry: "Technology", country: "Argentina")
    customer = ConvertProspectService.new(@prospect, @user).call

    assert_equal @prospect.company_name, customer.company_name
    assert_equal @prospect.country, customer.country
    assert_equal @prospect.industry, customer.industry
    assert_equal @prospect.responsible_consultant, customer.responsible_consultant
    assert_equal Date.current, customer.date_became_customer
    assert_equal Date.current, customer.last_activity_date
    assert_equal 0, customer.total_revenue
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

  test "conversion creates a primary contact from prospect inline fields" do
    @prospect.update!(primary_contact_phone: "+598 99 999 999")
    customer = ConvertProspectService.new(@prospect, @user).call

    assert_equal 1, customer.contacts.count
    contact = customer.contacts.first
    assert_equal @prospect.primary_contact_name, contact.name
    assert_equal @prospect.primary_contact_email, contact.email
    assert_equal "+598 99 999 999", contact.phone
    assert contact.primary
  end

  test "conversion copies collaborating consultants to new customer" do
    collaborator = create(:user)
    @prospect.consultant_assignments.create!(user: collaborator)

    customer = ConvertProspectService.new(@prospect, @user).call

    assert_equal [ collaborator ], customer.collaborating_consultants
  end

  test "conversion handles prospect with no collaborating consultants" do
    customer = ConvertProspectService.new(@prospect, @user).call

    assert_empty customer.collaborating_consultants
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
