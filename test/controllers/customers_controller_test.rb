require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer, :with_contact, responsible_consultant: @user)
  end

  # Index
  test "index lists customers" do
    get customers_path
    assert_response :success
    assert_includes response.body, @customer.company_name
  end

  test "index filters by status" do
    get customers_path(status: "active")
    assert_response :success
  end

  test "index filters by search" do
    get customers_path(search: @customer.company_name)
    assert_response :success
    assert_includes response.body, @customer.company_name
  end

  test "index sorts by company_name" do
    get customers_path(sort: "company_name", dir: "asc")
    assert_response :success
  end

  # Show
  test "show displays customer" do
    get customer_path(@customer)
    assert_response :success
    assert_includes response.body, @customer.company_name
  end

  # New / Create
  test "new renders form" do
    get new_customer_path
    assert_response :success
  end

  test "create with valid params including contact" do
    assert_difference "Customer.count", 1 do
      post customers_path, params: {
        customer: {
          company_name: "New Customer Co",
          status: "active",
          responsible_consultant_id: @user.id,
          date_became_customer: Date.current,
          last_activity_date: Date.current,
          contacts_attributes: {
            "0" => {
              name: "Primary Contact",
              email: "primary@newcustomer.com",
              phone: "555-0100",
              primary: true
            }
          }
        }
      }
    end

    assert_redirected_to customer_path(Customer.last)
  end

  test "create with invalid params re-renders form" do
    assert_no_difference "Customer.count" do
      post customers_path, params: {
        customer: { company_name: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit / Update
  test "edit renders form" do
    get edit_customer_path(@customer)
    assert_response :success
  end

  test "update with valid params" do
    patch customer_path(@customer), params: {
      customer: { company_name: "Updated Customer" }
    }

    assert_redirected_to customer_path(@customer)
    assert_equal "Updated Customer", @customer.reload.company_name
  end

  test "update with invalid params re-renders form" do
    patch customer_path(@customer), params: {
      customer: { company_name: "" }
    }

    assert_response :unprocessable_entity
  end

  # Destroy
  test "destroy deletes customer" do
    assert_difference "Customer.count", -1 do
      delete customer_path(@customer)
    end

    assert_redirected_to customers_path
  end

  test "destroy with linked proposals shows error" do
    create(:proposal, linkable: @customer)

    assert_no_difference "Customer.count" do
      delete customer_path(@customer)
    end

    assert_redirected_to customer_path(@customer)
  end

  # Auth
  test "unauthenticated user cannot access customers" do
    delete logout_path
    get customers_path
    assert_redirected_to login_path
  end
end
