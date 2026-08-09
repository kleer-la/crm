require "test_helper"

class TaskModalTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer)
    @prospect = create(:prospect)
    @proposal = create(:proposal, :draft, linkable: @customer)
  end

  # The task section is rendered inline. It deliberately has no turbo-frame wrapper:
  # writes answer with a redirect, so there is nothing to stream into, and a frame here
  # would capture every link inside it.

  def assert_task_section_for(record)
    assert_includes response.body, %(linkable_type=#{record.class.name})
    assert_includes response.body, %(linkable_id=#{record.id})
    assert_includes response.body, %(data-turbo-frame="modal")
  end

  test "customer show renders the task section with a modal link" do
    get customer_path(@customer)
    assert_response :success
    assert_task_section_for(@customer)
    assert_not_includes response.body, %(<turbo-frame id="tasks_customer_#{@customer.id}")
  end

  test "prospect show renders the task section with a modal link" do
    get prospect_path(@prospect)
    assert_response :success
    assert_task_section_for(@prospect)
    assert_not_includes response.body, %(<turbo-frame id="tasks_prospect_#{@prospect.id}")
  end

  test "proposal show renders the task section with a modal link" do
    get proposal_path(@proposal)
    assert_response :success
    assert_task_section_for(@proposal)
  end

  test "converted prospect show does not render the task section" do
    customer = create(:customer)
    @prospect.update!(status: :converted, converted_customer: customer)
    get prospect_path(@prospect)
    assert_response :success
    assert_not_includes response.body, %(linkable_id=#{@prospect.id})
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
