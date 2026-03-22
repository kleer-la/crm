require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "valid contact" do
    contact = build(:contact)
    assert contact.valid?
  end

  test "requires name" do
    contact = build(:contact, name: nil)
    assert_not contact.valid?
    assert_includes contact.errors[:name], "can't be blank"
  end

  test "requires email" do
    contact = build(:contact, email: nil)
    assert_not contact.valid?
    assert_includes contact.errors[:email], "can't be blank"
  end

  test "belongs to customer" do
    customer = create(:customer)
    contact = create(:contact, customer: customer)
    assert_equal customer, contact.customer
  end
end
