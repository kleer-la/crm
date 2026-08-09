require "test_helper"

# Guards the whole "form submits and the page silently does nothing" bug class.
#
# Turbo only applies a response when the thing it is looking for is actually there:
# a frame-scoped submit needs a matching <turbo-frame id="..."> in the response, and
# a turbo_stream response needs its target ids to exist on the page that submitted.
# When they don't match, Turbo applies nothing and the user sees a dead button.
class TurboFrameContractTest < ActionDispatch::IntegrationTest
  # What a real browser sends on a Turbo form submit. Requests without these headers
  # exercise code paths the browser never reaches, which is how such bugs stay green.
  TURBO_ACCEPT = "text/vnd.turbo-stream.html, text/html, application/xhtml+xml".freeze

  def frame_headers(id)
    { "Accept" => TURBO_ACCEPT, "Turbo-Frame" => id }
  end

  setup do
    @user = create(:user)
    sign_in(@user)
  end

  # Index filter bars submit into <turbo-frame id="results">.
  test "index pages return the results frame their filter bar targets" do
    { prospects_path => "prospects", customers_path => "customers",
      proposals_path => "proposals", tasks_path => "tasks" }.each do |path, name|
      get path, headers: frame_headers("results")
      assert_response :success
      assert_includes response.body, %(id="results"), "#{name} index is missing the results frame"
    end
  end

  # The linkable-type Stimulus controller sets frame.src to the new_* path and expects
  # a matching frame back, otherwise the dependent select never populates.
  test "task new returns the linkable_id_select frame for a frame request" do
    get new_task_path(linkable_type: "Customer"), headers: frame_headers("linkable_id_select")
    assert_response :success
    assert_includes response.body, %(id="linkable_id_select")
  end

  test "proposal new returns the linkable_id_select frame for a frame request" do
    get new_proposal_path(linkable_type: "Customer"), headers: frame_headers("linkable_id_select")
    assert_response :success
    assert_includes response.body, %(id="linkable_id_select")
  end

  # Pages hosting the task modal need the modal frame the section's links target.
  test "records hosting the task modal expose the modal frame" do
    customer = create(:customer)
    prospect = create(:prospect)
    proposal = create(:proposal, :draft, linkable: customer)

    [ customer_path(customer), prospect_path(prospect), proposal_path(proposal) ].each do |path|
      get path
      assert_response :success
      assert_includes response.body, %(id="modal"), "#{path} is missing the modal frame"
    end
  end

  # The task form deliberately breaks out of the modal frame, so no write response
  # depends on a DOM target existing anywhere.
  test "task form submits as a full page visit" do
    customer = create(:customer)

    get new_task_path(linkable_type: "Customer", linkable_id: customer.id),
      headers: frame_headers("modal")
    assert_response :success
    assert_includes response.body, %(data-turbo-frame="_top")
  end

  # messages#create replaces this id on failure; it has to be on the page already.
  test "conversation page exposes the reply_composer stream target" do
    conversation = create(:conversation)
    get conversation_path(conversation)
    assert_response :success
    assert_includes response.body, "reply_composer"
  end
end
