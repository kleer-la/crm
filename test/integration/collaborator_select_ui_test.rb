require "test_helper"

# Tests for the collaborator multi-select widget form submission behaviour.
# The widget produces the same hidden inputs as the old checkbox list, so
# we test that the controller correctly saves/clears collaborating_consultant_ids
# via standard form params — the same contract the JS widget relies on.
class CollaboratorSelectUiTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    @collaborator1 = create(:user, name: "Alice Smith")
    @collaborator2 = create(:user, name: "Bob Jones")
    sign_in(@admin)
  end

  # 4.2 Add collaborator to proposal, submit, verify persists
  test "submitting proposal form with collaborator ids saves association" do
    customer = create(:customer, :with_contact, responsible_consultant: @admin)
    proposal = create(:proposal, linkable: customer, responsible_consultant: @admin)

    patch proposal_path(proposal), params: {
      proposal: {
        title: proposal.title,
        status: proposal.status,
        responsible_consultant_id: @admin.id,
        collaborating_consultant_ids: [ @collaborator1.id, @collaborator2.id ]
      }
    }

    assert_redirected_to proposal_path(proposal)
    saved_ids = proposal.reload.collaborating_consultant_ids
    assert_includes saved_ids, @collaborator1.id
    assert_includes saved_ids, @collaborator2.id
  end

  # 4.3 Remove collaborator: submit with blank value clears association
  test "submitting proposal form with blank collaborating_consultant_ids clears association" do
    customer = create(:customer, :with_contact, responsible_consultant: @admin)
    proposal = create(:proposal, linkable: customer, responsible_consultant: @admin,
                      collaborating_consultant_ids: [ @collaborator1.id ])

    assert_includes proposal.reload.collaborating_consultant_ids, @collaborator1.id

    # Widget emits a single blank hidden input when no collaborators selected
    patch proposal_path(proposal), params: {
      proposal: {
        title: proposal.title,
        status: proposal.status,
        responsible_consultant_id: @admin.id,
        collaborating_consultant_ids: [ "" ]
      }
    }

    assert_redirected_to proposal_path(proposal)
    assert_empty proposal.reload.collaborating_consultant_ids
  end

  # 4.4 The multi-select partial renders consultant names in the dropdown
  # so the JS filter has data to work with
  test "proposal edit form includes consultant names for filter dropdown" do
    customer = create(:customer, :with_contact, responsible_consultant: @admin)
    proposal = create(:proposal, linkable: customer, responsible_consultant: @admin)

    get edit_proposal_path(proposal)
    assert_response :success
    assert_includes response.body, "Alice Smith"
    assert_includes response.body, "Bob Jones"
    assert_includes response.body, "data-multi-select-target=\"option\""
    assert_includes response.body, "data-controller=\"multi-select\""
  end

  # Prospects also use the shared partial
  test "submitting prospect form with collaborator ids saves association" do
    prospect = create(:prospect, responsible_consultant: @admin)

    patch prospect_path(prospect), params: {
      prospect: {
        company_name: prospect.company_name,
        primary_contact_name: prospect.primary_contact_name,
        primary_contact_email: prospect.primary_contact_email,
        status: prospect.status,
        responsible_consultant_id: @admin.id,
        collaborating_consultant_ids: [ @collaborator1.id ]
      }
    }

    assert_redirected_to prospect_path(prospect)
    assert_includes prospect.reload.collaborating_consultant_ids, @collaborator1.id
  end
end
