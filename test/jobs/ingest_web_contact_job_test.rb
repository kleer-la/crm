require "test_helper"

class IngestWebContactJobTest < ActiveSupport::TestCase
  def setup
    @intake_user = User.find_or_create_by!(email: "info@kleer.la") do |u|
      u.name = "Intake"
      u.role = :consultant
      u.active = true
    end
    @payload = {
      "name" => "Ana García",
      "email" => "ana@example.com",
      "company" => "Acme S.A.",
      "message" => "Quisiera info sobre fechas...",
      "context" => "https://kleer.la/cursos/scrum"
    }
  end

  test "exact Customer match attaches proposal to customer" do
    customer = create(:customer, company_name: "Acme S.A.", responsible_consultant: @intake_user)

    assert_no_difference "Prospect.count" do
      IngestWebContactJob.perform_now(@payload)
    end

    proposal = customer.proposals.last
    assert proposal
    assert_equal "draft", proposal.status
    assert_equal @intake_user, proposal.responsible_consultant
    assert_equal "Inbound web lead — Acme S.A.", proposal.title

    touchpoint = customer.activity_logs.touchpoint.last
    assert touchpoint
    assert_includes touchpoint.content, "Quisiera info"
  end

  test "exact Prospect match attaches proposal to prospect" do
    prospect = create(:prospect, company_name: "Acme S.A.", responsible_consultant: @intake_user)

    assert_no_difference "Prospect.count" do
      IngestWebContactJob.perform_now(@payload)
    end

    proposal = prospect.proposals.last
    assert proposal
    assert_equal @intake_user, proposal.responsible_consultant

    touchpoint = prospect.activity_logs.touchpoint.last
    assert touchpoint
  end

  test "fuzzy Customer match picks up company via trigram" do
    create(:customer, company_name: "Acme SA", responsible_consultant: @intake_user)

    assert_no_difference "Prospect.count" do
      IngestWebContactJob.perform_now(@payload)
    end

    customer = Customer.find_by!(company_name: "Acme SA")
    proposal = customer.proposals.last
    assert proposal
    assert_equal "Inbound web lead — Acme S.A.", proposal.title
  end

  test "fuzzy Prospect match when no Customer matches" do
    create(:prospect, company_name: "Acme SA", responsible_consultant: @intake_user)

    assert_no_difference "Prospect.count" do
      IngestWebContactJob.perform_now(@payload)
    end

    prospect = Prospect.find_by!(company_name: "Acme SA")
    proposal = prospect.proposals.last
    assert proposal
  end

  test "no match creates a new Prospect" do
    assert_difference "Prospect.count", 1 do
      IngestWebContactJob.perform_now(@payload)
    end

    prospect = Prospect.last
    assert_equal "Acme S.A.", prospect.company_name
    assert_equal "Ana García", prospect.primary_contact_name
    assert_equal "ana@example.com", prospect.primary_contact_email
    assert_equal "inbound", prospect.source
    assert_equal "new_prospect", prospect.status
    assert_equal @intake_user, prospect.responsible_consultant
    assert_equal Date.current, prospect.date_added
    assert_equal Date.current, prospect.last_activity_date
  end

  test "no match also creates a draft Proposal" do
    assert_difference "Proposal.count", 1 do
      IngestWebContactJob.perform_now(@payload)
    end

    prospect = Prospect.last
    proposal = Proposal.last
    assert_equal prospect, proposal.linkable
    assert_equal "draft", proposal.status
    assert_equal "Inbound web lead — Acme S.A.", proposal.title
    assert_equal @intake_user, proposal.responsible_consultant
    assert_equal "https://kleer.la/cursos/scrum", proposal.notes
  end

  test "email collision raises RecordInvalid" do
    create(:prospect, primary_contact_email: "ana@example.com", company_name: "Other Co",
           responsible_consultant: @intake_user)

    assert_raises ActiveRecord::RecordInvalid do
      IngestWebContactJob.perform_now(@payload)
    end
  end

  test "blank message still logs a touchpoint" do
    payload = @payload.merge("message" => "")

    IngestWebContactJob.perform_now(payload)

    prospect = Prospect.last
    touchpoint = prospect.activity_logs.touchpoint.last
    assert touchpoint
    assert_includes touchpoint.content, "No message provided"
  end

  test "missing Intake user raises RecordNotFound" do
    User.find_by(email: "info@kleer.la")&.destroy!

    assert_raises ActiveRecord::RecordNotFound do
      IngestWebContactJob.perform_now(@payload)
    end
  end

  test "all created records are owned by the Intake user" do
    IngestWebContactJob.perform_now(@payload)

    prospect = Prospect.last
    assert_equal @intake_user, prospect.responsible_consultant

    proposal = Proposal.last
    assert_equal @intake_user, proposal.responsible_consultant
  end
end
