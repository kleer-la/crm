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
    qualified = create(:prospect, :qualified, company_name: "Qualified Corp")
    get prospects_path(status: "qualified")
    assert_response :success
    assert_includes response.body, "Qualified Corp"
    assert_not_includes response.body, @prospect.company_name
  end

  test "index filters by source" do
    referral = create(:prospect, source: :referral, company_name: "Referral Inc")
    get prospects_path(source: "referral")
    assert_response :success
    assert_includes response.body, "Referral Inc"
  end

  test "index filters by search" do
    other = create(:prospect, company_name: "Unrelated LLC")
    get prospects_path(search: @prospect.company_name)
    assert_response :success
    assert_includes response.body, @prospect.company_name
    assert_not_includes response.body, "Unrelated LLC"
  end

  test "index sorts by company_name" do
    create(:prospect, company_name: "Alpha Co")
    create(:prospect, company_name: "Zulu Co")
    get prospects_path(sort: "company_name", dir: "asc")
    assert_response :success
    alpha_pos = response.body.index("Alpha Co")
    zulu_pos = response.body.index("Zulu Co")
    assert alpha_pos < zulu_pos, "Alpha Co should appear before Zulu Co in ascending order"
  end

  test "index combines filter and sort" do
    create(:prospect, :qualified, company_name: "Zulu Qualified")
    create(:prospect, :qualified, company_name: "Alpha Qualified")
    create(:prospect, company_name: "New Prospect Excluded")
    get prospects_path(status: "qualified", sort: "company_name", dir: "asc")
    assert_response :success
    assert_includes response.body, "Alpha Qualified"
    assert_includes response.body, "Zulu Qualified"
    assert_not_includes response.body, "New Prospect Excluded"
    alpha_pos = response.body.index("Alpha Qualified")
    zulu_pos = response.body.index("Zulu Qualified")
    assert alpha_pos < zulu_pos, "Filtered results should be sorted ascending"
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

  # Collaborating consultants
  test "update adds collaborating consultants" do
    collaborator = create(:user)
    patch prospect_path(@prospect), params: {
      prospect: { collaborating_consultant_ids: [ collaborator.id ] }
    }
    assert_redirected_to prospect_path(@prospect)
    assert_includes @prospect.reload.collaborating_consultants, collaborator
  end

  test "update removes collaborating consultants" do
    collaborator = create(:user)
    @prospect.collaborating_consultants << collaborator
    assert_includes @prospect.collaborating_consultants, collaborator

    patch prospect_path(@prospect), params: {
      prospect: { collaborating_consultant_ids: [ "" ] }
    }
    assert_redirected_to prospect_path(@prospect)
    assert_empty @prospect.reload.collaborating_consultants
  end

  # Auth
  test "unauthenticated user cannot access prospects" do
    delete logout_path
    get prospects_path
    assert_redirected_to login_path
  end
end
