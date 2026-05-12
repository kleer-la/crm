require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer, responsible_consultant: @user)
  end

  # --- Shell (index) ---

  test "index renders dashboard shell" do
    get root_path
    assert_response :success
    assert_includes response.body, "Dashboard"
  end

  test "index renders team KPI strip" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, estimated_value: 30_000)
    get root_path
    assert_response :success
    assert_includes response.body, "Team pipeline value"
    assert_includes response.body, "$30,000"
  end

  test "index renders both tab frames" do
    get root_path
    assert_response :success
    assert_includes response.body, 'id="dashboard-team"'
    assert_includes response.body, 'id="dashboard-mine"'
  end

  test "index mine frame has loading lazy" do
    get root_path
    assert_response :success
    assert_includes response.body, 'id="dashboard-mine"'
    assert_match(/turbo-frame[^>]*loading="lazy"[^>]*id="dashboard-mine"/, response.body)
  end

  test "index renders same page for admin and consultant" do
    get root_path
    consultant_body = response.body

    admin = create(:user, role: :admin)
    sign_in(admin)
    get root_path
    assert_response :success

    # Both see the same shell structure — no admin-specific sections
    assert_includes response.body, "Team pipeline value"
    assert_not_includes response.body, "Admin: Team overview"
    assert_not_includes consultant_body, "Admin: Team overview"
  end

  test "requires authentication" do
    delete logout_path
    get root_path
    assert_redirected_to login_path
  end

  # --- Team panel ---

  test "team_panel returns success" do
    get dashboard_team_panel_path
    assert_response :success
  end

  test "team_panel shows pending conversions" do
    prospect = create(:prospect, responsible_consultant: @user)
    create(:proposal, :won, linkable: prospect, responsible_consultant: @user, title: "Won Prop Alert XYZ")
    get dashboard_team_panel_path
    assert_response :success
    assert_includes response.body, "Pending conversions"
    assert_includes response.body, "Won Prop Alert XYZ"
  end

  test "team_panel shows stale proposals" do
    proposal = create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Stale Prop XYZ")
    proposal.activity_logs.where(entry_type: :touchpoint).update_all(occurred_at: 31.days.ago)
    get dashboard_team_panel_path
    assert_response :success
    assert_includes response.body, "Stale proposals"
    assert_includes response.body, "Stale Prop XYZ"
  end

  test "team_panel shows overdue tasks" do
    other = create(:user)
    create(:task, :overdue, assigned_to: other, linkable: @customer, title: "Team Overdue XYZ")
    get dashboard_team_panel_path
    assert_response :success
    assert_includes response.body, "Overdue tasks"
    assert_includes response.body, "Team Overdue XYZ"
  end

  test "team_panel overdue task alert disappears when task completed" do
    task = create(:task, :overdue, assigned_to: @user, linkable: @customer, title: "Done Overdue XYZ")
    task.update!(status: :done)
    get dashboard_team_panel_path
    assert_response :success
    # The alert box is only rendered when overdue tasks exist — heading absent means box is gone
    assert_not_includes response.body, "Overdue tasks"
  end

  test "team_panel shows open proposals" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Open Prop Team XYZ")
    get dashboard_team_panel_path
    assert_response :success
    assert_includes response.body, "Open proposals"
    assert_includes response.body, "Open Prop Team XYZ"
  end

  test "team_panel excludes closed proposals from open proposals list" do
    create(:proposal, :won, linkable: @customer, responsible_consultant: @user, title: "Won Prop Closed XYZ")
    get dashboard_team_panel_path
    assert_response :success
    # No open proposals exist — widget shows empty state
    assert_includes response.body, "No open proposals"
  end

  test "team_panel renders open proposals empty state" do
    get dashboard_team_panel_path
    assert_response :success
    assert_includes response.body, "No open proposals"
  end

  test "team_panel does not show overdue tasks section when none exist" do
    get dashboard_team_panel_path
    assert_response :success
    assert_not_includes response.body, "Overdue tasks"
  end

  test "team_panel alert links to proposal and prospect" do
    prospect = create(:prospect, responsible_consultant: @user)
    proposal = create(:proposal, :won, linkable: prospect, responsible_consultant: @user, title: "Alert Link Prop")
    get dashboard_team_panel_path
    assert_response :success
    assert_includes response.body, proposal_path(proposal)
    assert_includes response.body, prospect_path(prospect)
  end

  test "team_panel alerts have no dismiss controls" do
    prospect = create(:prospect, responsible_consultant: @user)
    create(:proposal, :won, linkable: prospect, responsible_consultant: @user, title: "Non-Dismissable Alert")
    get dashboard_team_panel_path
    assert_response :success
    # No dismiss/close buttons in the alert sections — alerts are data-driven only
    assert_no_match(/<button[^>]*>.*?[Dd]ismiss/m, response.body)
  end

  # --- Mine panel ---

  test "mine_panel returns success" do
    get dashboard_mine_panel_path
    assert_response :success
  end

  test "mine_panel shows my open tasks overdue first" do
    create(:task, :overdue, assigned_to: @user, linkable: @customer, title: "Overdue Task XYZ")
    create(:task, assigned_to: @user, linkable: @customer, title: "Future Task XYZ")
    get dashboard_mine_panel_path
    assert_response :success
    assert_includes response.body, "Overdue Task XYZ"
    assert_includes response.body, "Future Task XYZ"
    assert response.body.index("Overdue Task XYZ") < response.body.index("Future Task XYZ")
  end

  test "mine_panel shows my open proposals grouped by status" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Draft Prop XYZ")
    create(:proposal, :sent, linkable: @customer, responsible_consultant: @user, title: "Sent Prop XYZ")
    get dashboard_mine_panel_path
    assert_response :success
    assert_includes response.body, "Draft Prop XYZ"
    assert_includes response.body, "Sent Prop XYZ"
  end

  test "mine_panel shows my active prospects" do
    prospect = create(:prospect, responsible_consultant: @user)
    get dashboard_mine_panel_path
    assert_response :success
    assert_includes response.body, prospect.company_name
  end

  test "mine_panel shows my pending conversions" do
    prospect = create(:prospect, responsible_consultant: @user)
    create(:proposal, :won, linkable: prospect, responsible_consultant: @user, title: "Mine Pending Conv XYZ")
    get dashboard_mine_panel_path
    assert_response :success
    assert_includes response.body, "Pending conversions"
    assert_includes response.body, "Mine Pending Conv XYZ"
  end

  test "mine_panel shows my stale proposals" do
    proposal = create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Mine Stale XYZ")
    proposal.activity_logs.where(entry_type: :touchpoint).update_all(occurred_at: 31.days.ago)
    get dashboard_mine_panel_path
    assert_response :success
    assert_includes response.body, "Mine Stale XYZ"
  end

  test "mine_panel does not show other users tasks" do
    other = create(:user)
    other_customer = create(:customer, responsible_consultant: other)
    create(:task, assigned_to: other, linkable: other_customer, title: "Other User Task XYZ")
    get dashboard_mine_panel_path
    assert_response :success
    assert_not_includes response.body, "Other User Task XYZ"
  end

  test "mine_panel does not show other users proposals" do
    other = create(:user)
    other_customer = create(:customer, responsible_consultant: other)
    create(:proposal, linkable: other_customer, responsible_consultant: other, title: "Other Prop XYZ")
    get dashboard_mine_panel_path
    assert_response :success
    assert_not_includes response.body, "Other Prop XYZ"
  end

  test "mine_panel shows proposals where user is collaborator" do
    other = create(:user)
    proposal = create(:proposal, linkable: @customer, responsible_consultant: other, title: "Collab Prop XYZ")
    ConsultantAssignment.create!(user: @user, assignable: proposal)
    get dashboard_mine_panel_path
    assert_response :success
    assert_includes response.body, "Collab Prop XYZ"
  end

  test "mine_panel renders empty states" do
    get dashboard_mine_panel_path
    assert_response :success
    assert_includes response.body, "No open tasks"
    assert_includes response.body, "No open proposals"
    assert_includes response.body, "No active prospects"
  end

  # --- Lazy loading: Mine content not in shell response ---

  test "initial dashboard response does not contain mine panel content" do
    create(:task, assigned_to: @user, linkable: @customer, title: "Mine Only Task Content")
    get root_path
    assert_response :success
    assert_not_includes response.body, "Mine Only Task Content"
  end
end
