require "test_helper"

class ProposalTest < ActiveSupport::TestCase
  test "valid proposal" do
    proposal = build(:proposal)
    assert proposal.valid?
  end

  test "requires title" do
    proposal = build(:proposal, title: nil)
    assert_not proposal.valid?
    assert_includes proposal.errors[:title], "can't be blank"
  end

  test "requires description" do
    proposal = build(:proposal, description: nil)
    assert_not proposal.valid?
    assert_includes proposal.errors[:description], "can't be blank"
  end

  test "requires description to be non-blank" do
    proposal = build(:proposal, description: "")
    assert_not proposal.valid?
    assert_includes proposal.errors[:description], "can't be blank"
  end

  test "requires win_loss_reason when won" do
    proposal = build(:proposal, status: :won, win_loss_reason: nil)
    assert_not proposal.valid?
    assert_includes proposal.errors[:win_loss_reason], "can't be blank"
  end

  test "requires win_loss_reason when lost" do
    proposal = build(:proposal, status: :lost, win_loss_reason: nil)
    assert_not proposal.valid?
    assert_includes proposal.errors[:win_loss_reason], "can't be blank"
  end

  test "validates document url format" do
    proposal = build(:proposal, current_document_url: "not-a-url")
    assert_not proposal.valid?
    assert_includes proposal.errors[:current_document_url], "must be a valid URL"
  end

  test "allows valid document url" do
    proposal = build(:proposal, current_document_url: "https://docs.google.com/doc/123")
    assert proposal.valid?
  end

  test "allows blank document url" do
    proposal = build(:proposal, current_document_url: "")
    assert proposal.valid?
  end

  test "status enum values" do
    expected = { "draft" => 0, "sent" => 1, "under_review" => 2, "won" => 3, "lost" => 4, "cancelled" => 5 }
    assert_equal expected, Proposal.statuses
  end

  test "scope open includes draft sent under_review" do
    customer = create(:customer)
    draft = create(:proposal, status: :draft, linkable: customer)
    sent = create(:proposal, :sent, linkable: customer)
    won = create(:proposal, :won, linkable: customer)

    open = Proposal.open
    assert_includes open, draft
    assert_includes open, sent
    assert_not_includes open, won
  end

  test "scope closed includes won lost cancelled" do
    customer = create(:customer)
    draft = create(:proposal, status: :draft, linkable: customer)
    won = create(:proposal, :won, linkable: customer)

    closed = Proposal.closed
    assert_not_includes closed, draft
    assert_includes closed, won
  end

  test "polymorphic linkable to prospect" do
    prospect = create(:prospect)
    proposal = create(:proposal, linkable: prospect)
    assert_equal "Prospect", proposal.linkable_type
    assert_equal prospect, proposal.linkable
  end

  test "polymorphic linkable to customer" do
    customer = create(:customer)
    proposal = create(:proposal, linkable: customer)
    assert_equal "Customer", proposal.linkable_type
  end

  test "cannot win if linked prospect is disqualified" do
    prospect = create(:prospect, :disqualified)
    proposal = build(:proposal, linkable: prospect, status: :won, win_loss_reason: "Great", actual_close_date: Date.current)
    assert_not proposal.valid?
    assert proposal.errors[:base].any? { |e| e.include?("disqualified") }
  end

  test "can win if linked to customer" do
    proposal = build(:proposal, :won)
    assert proposal.valid?
  end

  test "auto-sets date_sent when status changes to sent" do
    proposal = create(:proposal)
    proposal.update!(status: :sent)
    assert_equal Date.current, proposal.date_sent
  end

  test "auto-sets actual_close_date when won" do
    proposal = create(:proposal)
    proposal.update!(status: :won, win_loss_reason: "Good")
    assert_equal Date.current, proposal.actual_close_date
  end

  test "auto-sets actual_close_date when lost" do
    proposal = create(:proposal)
    proposal.update!(status: :lost, win_loss_reason: "Price")
    assert_equal Date.current, proposal.actual_close_date
  end

  test "pending_conversion scope includes won prospect proposals" do
    prospect = create(:prospect)
    proposal = create(:proposal, :won, linkable: prospect)

    assert_includes Proposal.pending_conversion, proposal
  end

  test "pending_conversion scope excludes converted prospect proposals" do
    prospect = create(:prospect, status: :converted)
    proposal = create(:proposal, :won, linkable: prospect)

    assert_not_includes Proposal.pending_conversion, proposal
  end

  test "pending_conversion? returns true for won prospect proposal not converted" do
    prospect = create(:prospect)
    proposal = create(:proposal, :won, linkable: prospect)

    assert proposal.pending_conversion?
  end

  test "create proposal from proposals list requires linkable" do
    proposal = build(:proposal, linkable: nil)
    assert_not proposal.valid?
    assert_includes proposal.errors[:linkable], "must exist"
  end

  test "duplicate creates draft copy without dates or document" do
    original = create(:proposal, :sent, estimated_value: 10000, notes: "Important", current_document_url: "https://example.com/doc")
    dup = original.duplicate

    assert_equal original.title, dup.title
    assert_equal original.description, dup.description
    assert_equal original.linkable, dup.linkable
    assert_equal original.responsible_consultant, dup.responsible_consultant
    assert_equal original.estimated_value, dup.estimated_value
    assert_equal original.notes, dup.notes
    assert_equal "draft", dup.status
    assert_nil dup.date_sent
    assert_nil dup.actual_close_date
    assert_nil dup.current_document_url
  end

  test "recalculates customer revenue on status change" do
    customer = create(:customer)
    proposal = create(:proposal, linkable: customer, estimated_value: 20000)

    proposal.update!(status: :won, win_loss_reason: "Best bid")
    assert_equal 20000, customer.reload.total_revenue
  end

  test "stale scope includes open proposals with no recent touchpoint" do
    customer = create(:customer)
    proposal = create(:proposal, linkable: customer)
    # Only has a system event from creation callback — no touchpoints

    assert_includes Proposal.stale, proposal
  end

  test "stale scope excludes proposals with recent touchpoint" do
    customer = create(:customer)
    proposal = create(:proposal, linkable: customer)
    create(:activity_log, :touchpoint, loggable: proposal, user: proposal.responsible_consultant)

    assert_not_includes Proposal.stale, proposal
  end

  test "stale scope includes proposals with only recent system events" do
    customer = create(:customer)
    proposal = create(:proposal, linkable: customer)
    # System event from creation callback is recent, but touchpoints count only

    assert_includes Proposal.stale, proposal
  end

  test "stale scope excludes proposals with touchpoint within STALE_DAYS" do
    customer = create(:customer)
    proposal = create(:proposal, linkable: customer)
    touchpoint = create(:activity_log, :touchpoint, loggable: proposal, user: proposal.responsible_consultant)
    touchpoint.update_column(:created_at, (Proposal::STALE_DAYS - 1).days.ago)

    assert_not_includes Proposal.stale, proposal
  end

  test "stale scope includes proposals with touchpoint older than STALE_DAYS" do
    customer = create(:customer)
    proposal = create(:proposal, linkable: customer)
    touchpoint = create(:activity_log, :touchpoint, loggable: proposal, user: proposal.responsible_consultant)
    touchpoint.update_column(:created_at, (Proposal::STALE_DAYS + 1).days.ago)

    assert_includes Proposal.stale, proposal
  end

  test "stale scope excludes won proposals" do
    customer = create(:customer)
    proposal = create(:proposal, :won, linkable: customer)

    assert_not_includes Proposal.stale, proposal
  end
end
