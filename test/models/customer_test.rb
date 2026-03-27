require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  test "valid customer" do
    customer = build(:customer)
    assert customer.valid?
  end

  test "allows optional country" do
    customer = build(:customer, country: "Argentina")

    assert customer.valid?
    assert_equal "Argentina", customer.country
  end

  test "requires company_name" do
    customer = build(:customer, company_name: nil)
    assert_not customer.valid?
    assert_includes customer.errors[:company_name], "can't be blank"
  end

  test "requires unique company_name" do
    create(:customer, company_name: "Acme")
    customer = build(:customer, company_name: "Acme")
    assert_not customer.valid?
  end

  test "company_name unique across non-converted prospects" do
    create(:prospect, company_name: "Acme")
    customer = build(:customer, company_name: "Acme")
    assert_not customer.valid?
    assert_includes customer.errors[:company_name], "is already taken by an existing prospect"
  end

  test "status enum values" do
    assert_equal({ "active" => 0, "inactive" => 1, "at_risk" => 2 }, Customer.statuses)
  end

  test "recalculate_total_revenue sums won proposals" do
    customer = create(:customer)
    create(:proposal, :won, linkable: customer, estimated_value: 10000)
    create(:proposal, :won, linkable: customer, estimated_value: 25000)
    create(:proposal, :lost, linkable: customer) # should not count

    customer.recalculate_total_revenue!
    assert_equal 35000, customer.reload.total_revenue
  end

  test "must have at least one contact on update" do
    customer = create(:customer, :with_contact)
    customer.contacts.destroy_all
    assert_not customer.valid?
    assert_includes customer.errors[:base], "Customer must have at least one contact"
  end

  test "new customer without contacts is valid" do
    customer = build(:customer)
    assert customer.valid?
  end

  test "intention enum has four valid values and nil is permitted" do
    customer = build(:customer)
    assert customer.valid?
    assert_nil customer.intention

    %i[keep attract recapture expand].each do |val|
      customer.intention = val
      assert customer.valid?, "Expected #{val} to be valid"
    end
  end

  test "associations" do
    customer = create(:customer)
    assert_respond_to customer, :responsible_consultant
    assert_respond_to customer, :contacts
    assert_respond_to customer, :proposals
    assert_respond_to customer, :tasks
    assert_respond_to customer, :activity_logs
    assert_respond_to customer, :collaborating_consultants
  end
end
