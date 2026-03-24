require "test_helper"

class PipelineControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer)
    @prospect = create(:prospect, responsible_consultant: @user)
  end

  test "index shows active prospects and open proposals" do
    proposal = create(:proposal, linkable: @customer, responsible_consultant: @user)
    get pipeline_path
    assert_response :success
    assert_includes response.body, @prospect.company_name
    assert_includes response.body, proposal.title
  end

  test "index excludes converted prospects" do
    converted = create(:prospect, status: :converted, company_name: "ConvertedCo", primary_contact_email: "conv@test.com", responsible_consultant: @user)
    get pipeline_path
    assert_response :success
    assert_not_includes response.body, "ConvertedCo"
  end

  test "index excludes disqualified prospects" do
    disqualified = create(:prospect, :disqualified, company_name: "DisqualCo", primary_contact_email: "disq@test.com", responsible_consultant: @user)
    get pipeline_path
    assert_response :success
    assert_not_includes response.body, "DisqualCo"
  end

  test "index excludes won proposals" do
    won = create(:proposal, :won, linkable: @customer, responsible_consultant: @user, title: "Won Proposal XYZ")
    get pipeline_path
    assert_response :success
    assert_not_includes response.body, "Won Proposal XYZ"
  end

  test "index excludes lost proposals" do
    lost = create(:proposal, :lost, linkable: @customer, responsible_consultant: @user, title: "Lost Proposal XYZ")
    get pipeline_path
    assert_response :success
    assert_not_includes response.body, "Lost Proposal XYZ"
  end

  test "index displays summary bar with pipeline value" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, estimated_value: 25000)
    create(:proposal, linkable: @customer, responsible_consultant: @user, estimated_value: 35000)
    get pipeline_path
    assert_response :success
    assert_includes response.body, "$60,000"
  end

  test "index filters by consultant" do
    other_user = create(:user)
    other_prospect = create(:prospect, company_name: "OtherCo", primary_contact_email: "other@test.com", responsible_consultant: other_user)
    get pipeline_path(consultant_id: other_user.id)
    assert_response :success
    assert_includes response.body, "OtherCo"
    assert_not_includes response.body, @prospect.company_name
  end

  test "index filters by value range" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, estimated_value: 5000, title: "Small Deal")
    create(:proposal, linkable: @customer, responsible_consultant: @user, estimated_value: 100000, title: "Big Deal")
    get pipeline_path(value_min: 50000)
    assert_response :success
    assert_includes response.body, "Big Deal"
    assert_not_includes response.body, "Small Deal"
  end

  test "index filters by close date range" do
    create(:proposal, :sent, linkable: @customer, responsible_consultant: @user, expected_close_date: 10.days.from_now.to_date, title: "Soon Deal")
    create(:proposal, :sent, linkable: @customer, responsible_consultant: @user, expected_close_date: 90.days.from_now.to_date, title: "Later Deal")
    get pipeline_path(close_date_to: 30.days.from_now.to_date.to_s)
    assert_response :success
    assert_includes response.body, "Soon Deal"
    assert_not_includes response.body, "Later Deal"
  end

  test "index combines multiple filters with AND logic" do
    other_user = create(:user)
    # Matches both filters: correct consultant AND value >= 50000
    match = create(:proposal, linkable: @customer, responsible_consultant: @user, estimated_value: 75000, title: "Match Both")
    # Wrong consultant
    wrong_consultant = create(:proposal, linkable: @customer, responsible_consultant: other_user, estimated_value: 75000, title: "Wrong Consultant")
    # Too low value
    low_value = create(:proposal, linkable: @customer, responsible_consultant: @user, estimated_value: 5000, title: "Too Low Value")
    get pipeline_path(consultant_id: @user.id, value_min: 50000)
    assert_response :success
    assert_includes response.body, "Match Both"
    assert_not_includes response.body, "Wrong Consultant"
    assert_not_includes response.body, "Too Low Value"
  end

  test "index highlights overdue expected close dates" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, expected_close_date: 5.days.ago.to_date, title: "Overdue Proposal")
    get pipeline_path
    assert_response :success
    assert_includes response.body, "(overdue)"
  end

  test "requires authentication" do
    delete logout_path
    get pipeline_path
    assert_redirected_to login_path
  end
end
