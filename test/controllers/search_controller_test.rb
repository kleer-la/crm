require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
  end

  test "search returns prospects by company name" do
    prospect = create(:prospect, company_name: "Acme Corporation", responsible_consultant: @user)
    get search_path(q: "Acme")
    assert_response :success
    assert_includes response.body, "Acme Corporation"
    assert_includes response.body, "Prospect"
  end

  test "search returns customers by company name" do
    customer = create(:customer, company_name: "Beta Industries")
    get search_path(q: "Beta")
    assert_response :success
    assert_includes response.body, "Beta Industries"
    assert_includes response.body, "Customer"
  end

  test "search returns proposals by title" do
    customer = create(:customer)
    proposal = create(:proposal, title: "Cloud Migration Proposal", linkable: customer, responsible_consultant: @user)
    get search_path(q: "Cloud Migration")
    assert_response :success
    assert_includes response.body, "Cloud Migration Proposal"
    assert_includes response.body, "Proposal"
  end

  test "search returns mixed results" do
    prospect = create(:prospect, company_name: "TechCorp Solutions", responsible_consultant: @user)
    customer = create(:customer, company_name: "TechCorp Industries")
    get search_path(q: "TechCorp")
    assert_response :success
    assert_includes response.body, "TechCorp Solutions"
    assert_includes response.body, "TechCorp Industries"
  end

  test "search with no results shows empty state" do
    get search_path(q: "NonexistentXYZ123")
    assert_response :success
    assert_includes response.body, "No results found"
  end

  test "search with short query shows minimum length message" do
    get search_path(q: "A")
    assert_response :success
    assert_includes response.body, "at least 2 characters"
  end

  test "search responds to turbo_stream" do
    create(:prospect, company_name: "StreamTest Corp", responsible_consultant: @user)
    get search_path(q: "StreamTest"), as: :turbo_stream
    assert_response :success
  end

  test "requires authentication" do
    delete logout_path
    get search_path(q: "test")
    assert_redirected_to login_path
  end
end
