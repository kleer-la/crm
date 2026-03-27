require "test_helper"

class ProspectTest < ActiveSupport::TestCase
  test "valid prospect" do
    prospect = build(:prospect)
    assert prospect.valid?
  end

  test "allows optional country" do
    prospect = build(:prospect, country: "Argentina")

    assert prospect.valid?
    assert_equal "Argentina", prospect.country
  end

  test "requires company_name" do
    prospect = build(:prospect, company_name: nil)
    assert_not prospect.valid?
    assert_includes prospect.errors[:company_name], "can't be blank"
  end

  test "requires unique company_name within prospects" do
    create(:prospect, company_name: "Acme")
    prospect = build(:prospect, company_name: "Acme")
    assert_not prospect.valid?
    assert_includes prospect.errors[:company_name], "has already been taken"
  end

  test "company_name unique across customers" do
    create(:customer, company_name: "Acme")
    prospect = build(:prospect, company_name: "Acme")
    assert_not prospect.valid?
    assert_includes prospect.errors[:company_name], "is already taken by an existing customer"
  end

  test "email unique across customer contacts" do
    customer = create(:customer)
    create(:contact, customer: customer, email: "shared@example.com")
    prospect = build(:prospect, primary_contact_email: "shared@example.com")
    assert_not prospect.valid?
    assert_includes prospect.errors[:primary_contact_email], "is already used by an existing customer contact"
  end

  test "requires disqualification_reason when disqualified" do
    prospect = build(:prospect, status: :disqualified, disqualification_reason: nil)
    assert_not prospect.valid?
    assert_includes prospect.errors[:disqualification_reason], "can't be blank"
  end

  test "allows disqualified with reason" do
    prospect = build(:prospect, :disqualified)
    assert prospect.valid?
  end

  test "status enum values" do
    expected = { "new_prospect" => 0, "contacted" => 1, "qualified" => 2, "disqualified" => 3, "converted" => 4 }
    assert_equal expected, Prospect.statuses
  end

  test "source enum values" do
    expected = { "referral" => 0, "inbound" => 1, "outbound" => 2, "event" => 3, "other" => 4 }
    assert_equal expected, Prospect.sources
  end

  test "read_only when converted" do
    prospect = build(:prospect, status: :new_prospect)
    assert_not prospect.read_only?

    prospect.status = :converted
    assert prospect.read_only?
  end

  test "associations" do
    prospect = create(:prospect)
    assert_respond_to prospect, :responsible_consultant
    assert_respond_to prospect, :collaborating_consultants
    assert_respond_to prospect, :proposals
    assert_respond_to prospect, :tasks
    assert_respond_to prospect, :activity_logs
    assert_respond_to prospect, :converted_customer
  end
end
