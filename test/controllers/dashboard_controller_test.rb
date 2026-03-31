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
    assert_includes response.body, "My pipeline value"
    assert_includes response.body, "$30,000"
  end

  test "shows my open tasks with overdue first" do
    create(:task, :overdue, assigned_to: @user, linkable: @customer, title: "Overdue Task XYZ")
    create(:task, assigned_to: @user, linkable: @customer, title: "Future Task XYZ")
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
    assert_includes response.body, "Pending conversion"
    assert_includes response.body, "Won Prop Alert XYZ"
  end

  test "does not show pending conversion when prospect is converted" do
    prospect = create(:prospect, status: :converted, responsible_consultant: @user)
    create(:proposal, :won, linkable: prospect, responsible_consultant: @user, title: "Converted Prop XYZ")
    get root_path
    assert_response :success
    assert_no_match(/Pending conversion.*Converted Prop XYZ/m, response.body)
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
    create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Active Prop XYZ")
    # The creation callback already logged recent activity
    get root_path
    assert_response :success
    # Should not appear in stale section
    assert_no_match(/Stale proposal.*Active Prop XYZ/, response.body)
  end

  test "admin sees team-wide metrics" do
    admin = create(:user, role: :admin)
    sign_in(admin)
    create(:proposal, linkable: @customer, responsible_consultant: @user, estimated_value: 50000)
    get root_path
    assert_response :success
    assert_includes response.body, "Team pipeline value"
    assert_includes response.body, "$50,000"
  end

  test "admin sees all overdue tasks" do
    admin = create(:user, role: :admin)
    sign_in(admin)
    create(:task, :overdue, assigned_to: @user, linkable: @customer, title: "Team Overdue XYZ")
    get root_path
    assert_response :success
    assert_includes response.body, "All overdue tasks"
    assert_includes response.body, "Team Overdue XYZ"
  end

  test "pending conversion alert links to proposal and prospect" do
    prospect = create(:prospect, responsible_consultant: @user)
    proposal = create(:proposal, :won, linkable: prospect, responsible_consultant: @user, title: "Alert Link Prop")
    get root_path
    assert_response :success
    assert_includes response.body, proposal_path(proposal)
    assert_includes response.body, prospect_path(prospect)
  end

  test "stale proposal alert links to proposal" do
    proposal = create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Stale Link Prop")
    proposal.activity_logs.update_all(created_at: 31.days.ago)
    get root_path
    assert_response :success
    assert_includes response.body, proposal_path(proposal)
  end

  test "team alerts have no dismiss buttons" do
    prospect = create(:prospect, responsible_consultant: @user)
    create(:proposal, :won, linkable: prospect, responsible_consultant: @user, title: "Non-Dismissable Alert")
    stale = create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Stale Non-Dismissable")
    stale.activity_logs.update_all(created_at: 31.days.ago)
    get root_path
    assert_response :success
    assert_includes response.body, "Non-Dismissable Alert"
    assert_includes response.body, "Stale Non-Dismissable"
    # Alerts are purely data-driven — no dismiss/close controls
    team_alerts_section = response.body[/Team alerts.*?(?=<h2|<div class="grid|\z)/m]
    assert_not_includes team_alerts_section, "dismiss"
    assert_not_includes team_alerts_section, "close"
    assert_no_match(/<button[^>]*>.*?[Dd]ismiss/m, team_alerts_section)
  end

  test "consultant does not see admin section" do
    get root_path
    assert_response :success
    assert_not_includes response.body, "Admin: Team overview"
  end

  test "requires authentication" do
    delete logout_path
    get root_path
    assert_redirected_to login_path
  end
end
