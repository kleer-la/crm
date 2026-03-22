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
end
