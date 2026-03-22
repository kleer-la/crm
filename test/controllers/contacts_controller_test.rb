require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer, :with_contact, responsible_consultant: @user)
    @primary_contact = @customer.contacts.find_by(primary: true)
  end

  # New / Create
  test "new renders form" do
    get new_customer_contact_path(@customer)
    assert_response :success
  end

  test "create adds contact to customer" do
    assert_difference "@customer.contacts.count", 1 do
      post customer_contacts_path(@customer), params: {
        contact: {
          name: "New Contact",
          email: "newcontact@example.com",
          phone: "555-0200",
          role_title: "Director",
          primary: false
        }
      }
    end

    assert_redirected_to customer_path(@customer)
  end

  test "create with primary flag unsets existing primary" do
    post customer_contacts_path(@customer), params: {
      contact: {
        name: "New Primary",
        email: "newprimary@example.com",
        phone: "555-0300",
        primary: true
      }
    }

    assert_redirected_to customer_path(@customer)
    assert_not @primary_contact.reload.primary?
    assert @customer.contacts.find_by(email: "newprimary@example.com").primary?
  end

  test "create with invalid params re-renders form" do
    post customer_contacts_path(@customer), params: {
      contact: { name: "", email: "" }
    }

    assert_response :unprocessable_entity
  end

  # Edit / Update
  test "edit renders form" do
    get edit_customer_contact_path(@customer, @primary_contact)
    assert_response :success
  end

  test "update changes contact" do
    patch customer_contact_path(@customer, @primary_contact), params: {
      contact: { name: "Updated Name" }
    }

    assert_redirected_to customer_path(@customer)
    assert_equal "Updated Name", @primary_contact.reload.name
  end

  test "update to primary unsets other primaries" do
    second = create(:contact, customer: @customer, primary: false)

    patch customer_contact_path(@customer, second), params: {
      contact: { primary: true }
    }

    assert_redirected_to customer_path(@customer)
    assert second.reload.primary?
    assert_not @primary_contact.reload.primary?
  end

  # Destroy
  test "destroy removes non-last contact" do
    create(:contact, customer: @customer, primary: false)

    assert_difference "@customer.contacts.count", -1 do
      delete customer_contact_path(@customer, @primary_contact)
    end

    assert_redirected_to customer_path(@customer)
  end

  test "destroy promotes next contact to primary when primary deleted" do
    second = create(:contact, customer: @customer, primary: false)

    delete customer_contact_path(@customer, @primary_contact)

    assert second.reload.primary?
  end

  test "cannot destroy last contact" do
    assert_no_difference "@customer.contacts.count" do
      delete customer_contact_path(@customer, @primary_contact)
    end

    assert_redirected_to customer_path(@customer)
    assert_equal "Cannot remove the last contact.", flash[:alert]
  end

  # Auth
  test "unauthenticated user cannot access contacts" do
    delete logout_path
    get new_customer_contact_path(@customer)
    assert_redirected_to login_path
  end
end
