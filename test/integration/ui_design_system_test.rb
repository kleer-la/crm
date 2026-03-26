require "test_helper"

class UiDesignSystemTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  # Customers index — initials chip
  test "customers index renders indigo initials chip for each customer" do
    customer = create(:customer, :with_contact, company_name: "Acme Corp", responsible_consultant: @user)

    get customers_path
    assert_response :success

    assert_select "span.bg-indigo-100.text-indigo-700", text: "AC"
  end

  test "customers index renders indigo link for company name" do
    create(:customer, :with_contact, company_name: "Test Corp", responsible_consultant: @user)

    get customers_path
    assert_response :success

    assert_select "a.text-indigo-600", text: "Test Corp"
  end

  # Customers index — empty state
  test "customers index shows structured empty state when no customers match filter" do
    get customers_path, params: { search: "zzz_no_match_zzz" }
    assert_response :success

    assert_select "svg"
    assert_select "a[href=?]", new_customer_path
  end

  # Status badge color classes
  test "status_badge for active customer uses green classes" do
    customer = create(:customer, :with_contact, status: :active, responsible_consultant: @user)

    get customer_path(customer)
    assert_response :success

    assert_select "span.bg-green-100.text-green-700", text: "Active"
  end

  test "status_badge for inactive customer uses slate classes" do
    customer = create(:customer, :with_contact, status: :inactive, responsible_consultant: @user)

    get customer_path(customer)
    assert_response :success

    assert_select "span.bg-slate-100.text-slate-600", text: "Inactive"
  end

  # Sidebar uses slate classes
  test "layout sidebar has slate-700 background class" do
    create(:customer, :with_contact, responsible_consultant: @user)

    get customers_path
    assert_response :success

    assert_select "div.bg-slate-700"
    assert_select "div.bg-slate-800"
  end
end
