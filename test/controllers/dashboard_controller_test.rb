require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer, responsible_consultant: @user)
  end

  test "index renders dashboard" do
    get root_path
    assert_response :success
    assert_includes response.body, "Dashboard"
    assert_includes response.body, @user.display_name
  end

  test "shows personal metrics" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, estimated_value: 30000)
    get root_path
    assert_response :success
    assert_includes response.body, "My Pipeline Value"
    assert_includes response.body, "$30,000"
  end

  test "shows my open tasks with overdue first" do
    overdue_task = create(:task, :overdue, assigned_to: @user, linkable: @customer, title: "Overdue Task XYZ")
    future_task = create(:task, assigned_to: @user, linkable: @customer, title: "Future Task XYZ")
    get root_path
    assert_response :success
    assert_includes response.body, "Overdue Task XYZ"
    assert_includes response.body, "Future Task XYZ"
    # Overdue should appear before future
    assert response.body.index("Overdue Task XYZ") < response.body.index("Future Task XYZ")
  end

  test "shows my open proposals grouped by status" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Draft Prop XYZ")
    create(:proposal, :sent, linkable: @customer, responsible_consultant: @user, title: "Sent Prop XYZ")
    get root_path
    assert_response :success
    assert_includes response.body, "Draft Prop XYZ"
    assert_includes response.body, "Sent Prop XYZ"
  end

  test "shows my active prospects" do
    prospect = create(:prospect, responsible_consultant: @user)
    get root_path
    assert_response :success
    assert_includes response.body, prospect.company_name
  end

  test "shows pending conversion team alerts" do
    prospect = create(:prospect, responsible_consultant: @user)
    create(:proposal, :won, linkable: prospect, responsible_consultant: @user, title: "Won Prop Alert XYZ")
    get root_path
    assert_response :success
    assert_includes response.body, "Pending Conversion"
    assert_includes response.body, "Won Prop Alert XYZ"
  end

  test "does not show pending conversion when prospect is converted" do
    prospect = create(:prospect, status: :converted, responsible_consultant: @user)
    create(:proposal, :won, linkable: prospect, responsible_consultant: @user, title: "Converted Prop XYZ")
    get root_path
    assert_response :success
    assert_not_includes response.body, "Converted Prop XYZ"
  end

  test "shows stale proposal alerts" do
    proposal = create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Stale Prop XYZ")
    # Clear activity logs created by callbacks, make them old
    proposal.activity_logs.update_all(created_at: 31.days.ago)
    get root_path
    assert_response :success
    assert_includes response.body, "Stale Prop XYZ"
  end

  test "does not show stale alert for proposals with recent activity" do
    proposal = create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Active Prop XYZ")
    # The creation callback already logged recent activity
    get root_path
    assert_response :success
    # Should not appear in stale section
    assert_no_match(/Stale Proposal.*Active Prop XYZ/, response.body)
  end

  test "admin sees team-wide metrics" do
    admin = create(:user, role: :admin)
    sign_in(admin)
    create(:proposal, linkable: @customer, responsible_consultant: @user, estimated_value: 50000)
    get root_path
    assert_response :success
    assert_includes response.body, "Team Pipeline Value"
    assert_includes response.body, "$50,000"
  end

  test "admin sees all overdue tasks" do
    admin = create(:user, role: :admin)
    sign_in(admin)
    overdue = create(:task, :overdue, assigned_to: @user, linkable: @customer, title: "Team Overdue XYZ")
    get root_path
    assert_response :success
    assert_includes response.body, "All Overdue Tasks"
    assert_includes response.body, "Team Overdue XYZ"
  end

  test "consultant does not see admin section" do
    get root_path
    assert_response :success
    assert_not_includes response.body, "Admin: Team Overview"
  end

  test "requires authentication" do
    delete logout_path
    get root_path
    assert_redirected_to login_path
  end
end
