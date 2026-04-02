require "test_helper"

class System::DeploymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @deployment = create(:deployment, deployed_at: 1.hour.ago)
  end

  test "redirects unauthenticated user to login" do
    get system_deployments_path
    assert_redirected_to login_path
  end

  test "authenticated user can view deployments" do
    sign_in @user
    get system_deployments_path
    assert_response :success
  end

  test "shows latest deployment by default" do
    older = create(:deployment, deployed_at: 2.hours.ago, version: "older")
    sign_in @user
    get system_deployments_path
    assert_response :success
    assert_includes response.body, @deployment.version
  end

  test "shows selected deployment via id param" do
    older = create(:deployment, deployed_at: 2.hours.ago, version: "older123")
    sign_in @user
    get system_deployments_path(id: older.id)
    assert_response :success
    assert_includes response.body, "older123"
  end

  test "handles pagination" do
    25.times { |i| create(:deployment, deployed_at: (i + 2).hours.ago) }
    sign_in @user
    get system_deployments_path
    assert_response :success
    get system_deployments_path(page: 2)
    assert_response :success
  end

  test "handles no deployments gracefully" do
    Deployment.destroy_all
    sign_in @user
    get system_deployments_path
    assert_response :success
    assert_includes response.body, "No deployment"
  end
end
