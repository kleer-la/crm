require "test_helper"

class ProspectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @prospect = create(:prospect, responsible_consultant: @user)
  end

  # Index
  test "index lists prospects" do
    get prospects_path
    assert_response :success
    assert_includes response.body, @prospect.company_name
  end

  test "index filters by status" do
    qualified = create(:prospect, :qualified)
    get prospects_path(status: "qualified")
    assert_response :success
  end

  test "index filters by source" do
    create(:prospect, source: :referral)
    get prospects_path(source: "referral")
    assert_response :success
  end

  test "index filters by search" do
    get prospects_path(search: @prospect.company_name)
    assert_response :success
    assert_includes response.body, @prospect.company_name
  end

  test "index sorts by company_name" do
    get prospects_path(sort: "company_name", dir: "asc")
    assert_response :success
  end

  # Show
  test "show displays prospect" do
    get prospect_path(@prospect)
    assert_response :success
    assert_includes response.body, @prospect.company_name
  end

  # New / Create
  test "new renders form" do
    get new_prospect_path
    assert_response :success
  end

  test "create with valid params" do
    assert_difference "Prospect.count", 1 do
      post prospects_path, params: {
        prospect: {
          company_name: "New Prospect Co",
          primary_contact_name: "John Doe",
          primary_contact_email: "john@newprospect.com",
          source: "referral",
          status: "new_prospect",
          responsible_consultant_id: @user.id,
          date_added: Date.current,
          last_activity_date: Date.current
        }
      }
    end

    assert_redirected_to prospect_path(Prospect.last)
  end

  test "create with invalid params re-renders form" do
    assert_no_difference "Prospect.count" do
      post prospects_path, params: {
        prospect: { company_name: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit / Update
  test "edit renders form" do
    get edit_prospect_path(@prospect)
    assert_response :success
  end

  test "update with valid params" do
    patch prospect_path(@prospect), params: {
      prospect: { company_name: "Updated Name" }
    }

    assert_redirected_to prospect_path(@prospect)
    assert_equal "Updated Name", @prospect.reload.company_name
  end

  test "update with invalid params re-renders form" do
    patch prospect_path(@prospect), params: {
      prospect: { company_name: "" }
    }

    assert_response :unprocessable_entity
  end

  # Destroy
  test "destroy deletes prospect" do
    assert_difference "Prospect.count", -1 do
      delete prospect_path(@prospect)
    end

    assert_redirected_to prospects_path
  end

  test "destroy with linked proposals shows error" do
    create(:proposal, linkable: @prospect)

    assert_no_difference "Prospect.count" do
      delete prospect_path(@prospect)
    end

    assert_redirected_to prospect_path(@prospect)
  end

  # Disqualify
  test "disqualify with reason" do
    patch disqualify_prospect_path(@prospect), params: {
      prospect: { disqualification_reason: "Budget too small" }
    }

    assert_redirected_to prospect_path(@prospect)
    assert_equal "disqualified", @prospect.reload.status
    assert_equal "Budget too small", @prospect.disqualification_reason
  end

  test "disqualify without reason shows error" do
    patch disqualify_prospect_path(@prospect), params: {
      prospect: { disqualification_reason: "" }
    }

    assert_redirected_to prospect_path(@prospect)
    assert_equal "new_prospect", @prospect.reload.status
  end

  # Convert
  test "convert creates customer from prospect" do
    assert_difference [ "Customer.count" ], 1 do
      patch convert_prospect_path(@prospect)
    end

    assert_redirected_to customer_path(Customer.last)
    assert_equal "converted", @prospect.reload.status
  end

  test "convert fails for disqualified prospect" do
    @prospect.update!(status: :disqualified, disqualification_reason: "Not a fit")

    assert_no_difference "Customer.count" do
      patch convert_prospect_path(@prospect)
    end

    assert_redirected_to prospect_path(@prospect)
  end

  # Read-only converted prospect
  test "cannot edit converted prospect" do
    customer = create(:customer)
    @prospect.update!(status: :converted, converted_customer: customer)

    get edit_prospect_path(@prospect)
    assert_redirected_to prospect_path(@prospect)
  end

  test "cannot update converted prospect" do
    customer = create(:customer)
    @prospect.update!(status: :converted, converted_customer: customer)

    patch prospect_path(@prospect), params: {
      prospect: { company_name: "Changed" }
    }
    assert_redirected_to prospect_path(@prospect)
  end

  # Auth
  test "unauthenticated user cannot access prospects" do
    delete logout_path
    get prospects_path
    assert_redirected_to login_path
  end
end
