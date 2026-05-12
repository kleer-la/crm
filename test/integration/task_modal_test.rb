require "test_helper"

class TaskModalTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer)
    @prospect = create(:prospect)
    @proposal = create(:proposal, :draft, linkable: @customer)
  end

  # Turbo Frame presence on show pages

  test "customer show includes tasks turbo frame with correct dom id" do
    get customer_path(@customer)
    assert_response :success
    assert_includes response.body, %(<turbo-frame id="tasks_customer_#{@customer.id}")
  end

  test "prospect show includes tasks turbo frame with correct dom id" do
    get prospect_path(@prospect)
    assert_response :success
    assert_includes response.body, %(<turbo-frame id="tasks_prospect_#{@prospect.id}")
  end

  test "proposal show includes tasks turbo frame with correct dom id" do
    get proposal_path(@proposal)
    assert_response :success
    assert_includes response.body, %(<turbo-frame id="tasks_proposal_#{@proposal.id}")
  end

  test "converted prospect show does not include tasks turbo frame" do
    customer = create(:customer)
    @prospect.update!(status: :converted, converted_customer: customer)
    get prospect_path(@prospect)
    assert_response :success
    assert_not_includes response.body, %(<turbo-frame id="tasks_prospect_#{@prospect.id}")
  end

  # New task form renders inside modal frame when turbo-frame request

  test "new task renders modal frame when turbo-frame request header present" do
    get new_task_path(linkable_type: "Customer", linkable_id: @customer.id),
        headers: { "Turbo-Frame" => "modal" }
    assert_response :success
    assert_includes response.body, %(<turbo-frame id="modal")
    assert_includes response.body, "<dialog"
  end

  test "new task renders full page when no turbo-frame request header" do
    get new_task_path(linkable_type: "Customer", linkable_id: @customer.id)
    assert_response :success
    assert_not_includes response.body, "<dialog"
    assert_includes response.body, "New task for"
  end
end
