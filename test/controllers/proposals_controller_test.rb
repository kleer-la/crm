require "test_helper"

class ProposalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in(@user)
    @customer = create(:customer)
    @proposal = create(:proposal, linkable: @customer, responsible_consultant: @user)
  end

  # Index
  test "index lists proposals" do
    get proposals_path
    assert_response :success
    assert_includes response.body, @proposal.title
  end

  test "index filters by status" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, status: :sent, title: "Sent Proposal")
    get proposals_path(status: "sent")
    assert_response :success
    assert_includes response.body, "Sent Proposal"
    assert_not_includes response.body, @proposal.title
  end

  test "index filters by search" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Unrelated Prop")
    get proposals_path(search: @proposal.title)
    assert_response :success
    assert_includes response.body, @proposal.title
    assert_not_includes response.body, "Unrelated Prop"
  end

  test "index sorts by title" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Alpha Proposal")
    create(:proposal, linkable: @customer, responsible_consultant: @user, title: "Zulu Proposal")
    get proposals_path(sort: "title", dir: "asc")
    assert_response :success
    alpha_pos = response.body.index("Alpha Proposal")
    zulu_pos = response.body.index("Zulu Proposal")
    assert alpha_pos < zulu_pos, "Alpha should appear before Zulu in ascending order"
  end

  test "index combines filter and sort" do
    create(:proposal, linkable: @customer, responsible_consultant: @user, status: :sent, title: "Zulu Sent")
    create(:proposal, linkable: @customer, responsible_consultant: @user, status: :sent, title: "Alpha Sent")
    get proposals_path(status: "sent", sort: "title", dir: "asc")
    assert_response :success
    assert_includes response.body, "Alpha Sent"
    assert_includes response.body, "Zulu Sent"
    assert_not_includes response.body, @proposal.title
    assert response.body.index("Alpha Sent") < response.body.index("Zulu Sent")
  end

  # Show
  test "show displays proposal" do
    get proposal_path(@proposal)
    assert_response :success
    assert_includes response.body, @proposal.title
    assert_includes response.body, @proposal.description
  end

  # New / Create
  test "new renders form" do
    get new_proposal_path
    assert_response :success
  end

  test "new pre-fills linkable from params" do
    get new_proposal_path(linkable_type: "Customer", linkable_id: @customer.id)
    assert_response :success
  end

  test "create with valid params" do
    assert_difference "Proposal.count", 1 do
      post proposals_path, params: {
        proposal: {
          title: "New Proposal",
          description: "A detailed description of the proposal",
          linkable_type: "Customer",
          linkable_id: @customer.id,
          responsible_consultant_id: @user.id,
          estimated_value: 15000
        }
      }
    end

    assert_redirected_to proposal_path(Proposal.last)
    assert_equal "A detailed description of the proposal", Proposal.last.description
  end

  test "create without description re-renders form" do
    assert_no_difference "Proposal.count" do
      post proposals_path, params: {
        proposal: {
          title: "No Desc Proposal",
          description: "",
          linkable_type: "Customer",
          linkable_id: @customer.id,
          responsible_consultant_id: @user.id
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with invalid params re-renders form" do
    assert_no_difference "Proposal.count" do
      post proposals_path, params: {
        proposal: { title: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit / Update
  test "edit renders form" do
    get edit_proposal_path(@proposal)
    assert_response :success
  end

  test "update with valid params" do
    patch proposal_path(@proposal), params: {
      proposal: { title: "Updated Title", description: "Updated description" }
    }

    assert_redirected_to proposal_path(@proposal)
    assert_equal "Updated Title", @proposal.reload.title
    assert_equal "Updated description", @proposal.description
  end

  # Destroy
  test "destroy deletes proposal" do
    assert_difference "Proposal.count", -1 do
      delete proposal_path(@proposal)
    end

    assert_redirected_to proposals_path
  end

  test "destroy with linked tasks shows error" do
    create(:task, linkable: @proposal)

    assert_no_difference "Proposal.count" do
      delete proposal_path(@proposal)
    end

    assert_redirected_to proposal_path(@proposal)
  end

  # Mark as Won
  test "mark_won with reason" do
    patch mark_won_proposal_path(@proposal), params: {
      proposal: { win_loss_reason: "Best price" }
    }

    assert_redirected_to proposal_path(@proposal)
    assert_equal "won", @proposal.reload.status
    assert_equal "Best price", @proposal.win_loss_reason
    assert_equal Date.current, @proposal.actual_close_date
  end

  test "mark_won without reason fails" do
    patch mark_won_proposal_path(@proposal), params: {
      proposal: { win_loss_reason: "" }
    }

    assert_redirected_to proposal_path(@proposal)
    assert_equal "draft", @proposal.reload.status
  end

  test "mark_won on proposal linked to disqualified prospect fails" do
    prospect = create(:prospect, :disqualified)
    proposal = create(:proposal, linkable: prospect, responsible_consultant: @user)

    patch mark_won_proposal_path(proposal), params: {
      proposal: { win_loss_reason: "Great" }
    }

    assert_redirected_to proposal_path(proposal)
    assert_equal "draft", proposal.reload.status
  end

  # Mark as Lost
  test "mark_lost with reason" do
    patch mark_lost_proposal_path(@proposal), params: {
      proposal: { win_loss_reason: "Too expensive" }
    }

    assert_redirected_to proposal_path(@proposal)
    assert_equal "lost", @proposal.reload.status
    assert_equal "Too expensive", @proposal.win_loss_reason
    assert_equal Date.current, @proposal.actual_close_date
  end

  test "mark_lost without reason fails" do
    patch mark_lost_proposal_path(@proposal), params: {
      proposal: { win_loss_reason: "" }
    }

    assert_redirected_to proposal_path(@proposal)
    assert_equal "draft", @proposal.reload.status
  end

  # Duplicate
  test "duplicate creates new draft" do
    assert_difference "Proposal.count", 1 do
      post duplicate_proposal_path(@proposal)
    end

    new_proposal = Proposal.last
    assert_equal "draft", new_proposal.status
    assert_equal @proposal.title, new_proposal.title
    assert_redirected_to edit_proposal_path(new_proposal)
  end

  # Archive Document
  test "archive_document archives current and sets new url" do
    @proposal.update!(current_document_url: "https://old.example.com/doc")

    assert_difference "DocumentVersion.count", 1 do
      post archive_document_proposal_path(@proposal), params: {
        label: "V1",
        new_url: "https://new.example.com/doc"
      }
    end

    assert_redirected_to proposal_path(@proposal)
    assert_equal "https://new.example.com/doc", @proposal.reload.current_document_url

    version = @proposal.document_versions.last
    assert_equal "V1", version.label
    assert_equal "https://old.example.com/doc", version.url
    assert_equal @user, version.archived_by
  end

  test "archive_document with no current url fails" do
    post archive_document_proposal_path(@proposal), params: {
      label: "V1",
      new_url: "https://example.com/doc"
    }

    assert_redirected_to proposal_path(@proposal)
    assert_equal "No document link to archive.", flash[:alert]
  end

  # Archive prompt
  test "show displays archive prompt when document url exists" do
    @proposal.update!(current_document_url: "https://docs.example.com/proposal")
    get proposal_path(@proposal)
    assert_response :success
    assert_includes response.body, "Replace & archive"
    assert_includes response.body, "archive-modal"
    assert_includes response.body, "Archive label"
  end

  test "show does not display archive prompt when no document url" do
    @proposal.update_column(:current_document_url, nil)
    get proposal_path(@proposal)
    assert_response :success
    assert_includes response.body, "No document link set."
    assert_not_includes response.body, "archive-modal"
  end

  # Auth
  test "unauthenticated user cannot access proposals" do
    delete logout_path
    get proposals_path
    assert_redirected_to login_path
  end
end
