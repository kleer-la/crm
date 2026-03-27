require "test_helper"

class CsvImportExecutionServiceTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin, name: "Admin User")
  end

  # --- User import ---

  test "creates users from parsed rows" do
    rows = [
      { row_number: 2, name: "Alice", email: "alice@example.com", role: "consultant" },
      { row_number: 3, name: "Bob", email: "bob@example.com", role: "admin" }
    ]

    result = CsvImportExecutionService.new(rows, :user, @admin).call

    assert_equal 2, result[:created_count]
    assert_equal 0, result[:skipped_count]
    assert_equal 0, result[:error_count]

    alice = User.find_by(email: "alice@example.com")
    assert_equal "Alice", alice.name
    assert alice.consultant?
    assert_nil alice.google_uid

    bob = User.find_by(email: "bob@example.com")
    assert bob.admin?
  end

  test "defaults user role to consultant when blank" do
    rows = [ { row_number: 2, name: "Alice", email: "alice@example.com", role: nil } ]

    CsvImportExecutionService.new(rows, :user, @admin).call

    assert User.find_by(email: "alice@example.com").consultant?
  end

  test "skips users with existing email" do
    create(:user, email: "existing@example.com")
    rows = [ { row_number: 2, name: "Existing", email: "existing@example.com", role: "consultant" } ]

    result = CsvImportExecutionService.new(rows, :user, @admin).call

    assert_equal 0, result[:created_count]
    assert_equal 1, result[:skipped_count]
  end

  # --- Customer import ---

  test "creates customers from parsed rows" do
    consultant = create(:user, name: "Pablo Lis")
    rows = [
      { row_number: 2, company_name: "Acme Corp", country: "Argentina", industry: "Tech", responsible_consultant_name: "Pablo Lis", last_activity_date: Date.new(2024, 3, 11) }
    ]

    result = CsvImportExecutionService.new(rows, :customer, @admin).call

    assert_equal 1, result[:created_count]
    customer = Customer.find_by(company_name: "Acme Corp")
    assert customer.active?
    assert_equal consultant, customer.responsible_consultant
    assert_equal "Argentina", customer.country
    assert_equal "Tech", customer.industry
    assert_equal Date.new(2024, 3, 11), customer.last_activity_date # restored via update_column after callback
    assert_nil customer.date_became_customer # cleared by import
  end

  test "customer defaults last_activity_date to today when nil" do
    rows = [ { row_number: 2, company_name: "Acme", country: nil, industry: nil, responsible_consultant_name: nil, last_activity_date: nil } ]

    CsvImportExecutionService.new(rows, :customer, @admin).call

    assert_nil Customer.find_by(company_name: "Acme").last_activity_date # nil preserved via update_column
    assert_nil Customer.find_by(company_name: "Acme").country
  end

  test "customer falls back to importing admin when consultant not matched" do
    rows = [ { row_number: 2, company_name: "Acme", country: nil, industry: nil, responsible_consultant_name: "Unknown Person", last_activity_date: nil } ]

    CsvImportExecutionService.new(rows, :customer, @admin).call

    assert_equal @admin, Customer.find_by(company_name: "Acme").responsible_consultant
  end

  # --- Consultant matching ---

  test "matches consultant by exact name" do
    pablo = create(:user, name: "Pablo Lis")
    rows = [ { row_number: 2, company_name: "TestCo", country: nil, industry: nil, responsible_consultant_name: "Pablo Lis", last_activity_date: nil } ]

    CsvImportExecutionService.new(rows, :customer, @admin).call

    assert_equal pablo, Customer.find_by(company_name: "TestCo").responsible_consultant
  end

  test "matches consultant by partial ILIKE" do
    andres = create(:user, name: "Andrés Juárez")
    rows = [ { row_number: 2, company_name: "TestCo", country: nil, industry: nil, responsible_consultant_name: "Andrés J", last_activity_date: nil } ]

    CsvImportExecutionService.new(rows, :customer, @admin).call

    assert_equal andres, Customer.find_by(company_name: "TestCo").responsible_consultant
  end

  test "falls back to importing admin when no consultant match" do
    rows = [ { row_number: 2, company_name: "TestCo", country: nil, industry: nil, responsible_consultant_name: "Nobody", last_activity_date: nil } ]

    CsvImportExecutionService.new(rows, :customer, @admin).call

    assert_equal @admin, Customer.find_by(company_name: "TestCo").responsible_consultant
  end

  # --- Proposal import ---

  test "creates proposals linked to existing customers" do
    consultant = create(:user, name: "Pablo Lis")
    customer = create(:customer, company_name: "UTE UY", responsible_consultant: consultant)
    create(:contact, customer: customer, primary: true)

    rows = [
      {
        row_number: 2, title: "Curso Agilidad", linkable_company_name: "UTE UY",
        responsible_consultant_name: "Pablo Lis", status: "lost",
        estimated_value: BigDecimal("2500"), final_value: nil,
        current_document_url: nil, notes: nil, date_asked: Date.new(2024, 3, 11),
        actual_close_date: nil, contact: { name: "Lucila", email: "lucila@ute.com" }
      }
    ]

    result = CsvImportExecutionService.new(rows, :proposal, @admin).call

    assert_equal 1, result[:created_count]
    proposal = Proposal.find_by(title: "Curso Agilidad")
    assert_equal customer, proposal.linkable
    assert_equal consultant, proposal.responsible_consultant
    assert proposal.lost?
    assert_equal "Imported", proposal.win_loss_reason
    assert_equal BigDecimal("2500"), proposal.estimated_value
  end

  test "sets win_loss_reason to Imported for won proposals" do
    customer = create(:customer, company_name: "WinCo")
    create(:contact, customer: customer, primary: true)

    rows = [
      {
        row_number: 2, title: "Won Deal", linkable_company_name: "WinCo",
        responsible_consultant_name: nil, status: "won",
        estimated_value: BigDecimal("5000"), final_value: nil,
        current_document_url: nil, notes: nil, date_asked: nil,
        actual_close_date: nil, contact: nil
      }
    ]

    CsvImportExecutionService.new(rows, :proposal, @admin).call

    assert_equal "Imported", Proposal.find_by(title: "Won Deal").win_loss_reason
  end

  test "does not set win_loss_reason for draft proposals" do
    customer = create(:customer, company_name: "DraftCo")
    create(:contact, customer: customer, primary: true)

    rows = [
      {
        row_number: 2, title: "Draft Deal", linkable_company_name: "DraftCo",
        responsible_consultant_name: nil, status: "draft",
        estimated_value: nil, final_value: nil,
        current_document_url: nil, notes: nil, date_asked: nil,
        actual_close_date: nil, contact: nil
      }
    ]

    CsvImportExecutionService.new(rows, :proposal, @admin).call

    assert_nil Proposal.find_by(title: "Draft Deal").win_loss_reason
  end

  test "errors when proposal linkable not found" do
    rows = [
      {
        row_number: 2, title: "Orphan Proposal", linkable_company_name: "NonExistent Corp",
        responsible_consultant_name: nil, status: "draft",
        estimated_value: nil, final_value: nil,
        current_document_url: nil, notes: nil, date_asked: nil,
        actual_close_date: nil, contact: nil
      }
    ]

    result = CsvImportExecutionService.new(rows, :proposal, @admin).call

    assert_equal 0, result[:created_count]
    assert_equal 1, result[:error_count]
    assert_includes result[:errors].first[:messages].first, "No matching Customer or Prospect"
  end

  test "matches linkable case-insensitively" do
    customer = create(:customer, company_name: "Acme Corp")
    create(:contact, customer: customer, primary: true)

    rows = [
      {
        row_number: 2, title: "Case Test", linkable_company_name: "acme corp",
        responsible_consultant_name: nil, status: "draft",
        estimated_value: nil, final_value: nil,
        current_document_url: nil, notes: nil, date_asked: nil,
        actual_close_date: nil, contact: nil
      }
    ]

    result = CsvImportExecutionService.new(rows, :proposal, @admin).call

    assert_equal 1, result[:created_count]
    assert_equal customer, Proposal.find_by(title: "Case Test").linkable
  end

  # --- Contact extraction ---

  test "creates contact on customer during proposal import" do
    customer = create(:customer, company_name: "ContactCo")
    create(:contact, customer: customer, primary: true)

    rows = [
      {
        row_number: 2, title: "Contact Test", linkable_company_name: "ContactCo",
        responsible_consultant_name: nil, status: "draft",
        estimated_value: nil, final_value: nil,
        current_document_url: nil, notes: nil, date_asked: nil,
        actual_close_date: nil, contact: { name: "New Person", email: "new@contactco.com" }
      }
    ]

    CsvImportExecutionService.new(rows, :proposal, @admin).call

    contact = customer.contacts.find_by(email: "new@contactco.com")
    assert_not_nil contact
    assert_equal "New Person", contact.name
    assert_not contact.primary? # not first contact, customer already had one
  end

  test "marks first contact as primary" do
    customer = create(:customer, company_name: "NoCo")

    rows = [
      {
        row_number: 2, title: "First Contact", linkable_company_name: "NoCo",
        responsible_consultant_name: nil, status: "draft",
        estimated_value: nil, final_value: nil,
        current_document_url: nil, notes: nil, date_asked: nil,
        actual_close_date: nil, contact: { name: "First Person", email: "first@noco.com" }
      }
    ]

    CsvImportExecutionService.new(rows, :proposal, @admin).call

    contact = customer.contacts.find_by(email: "first@noco.com")
    assert contact.primary?
  end

  test "finds existing contact by email instead of creating duplicate" do
    customer = create(:customer, company_name: "DupCo")
    create(:contact, customer: customer, name: "Existing", email: "existing@dupco.com", primary: true)

    rows = [
      {
        row_number: 2, title: "Dup Contact", linkable_company_name: "DupCo",
        responsible_consultant_name: nil, status: "draft",
        estimated_value: nil, final_value: nil,
        current_document_url: nil, notes: nil, date_asked: nil,
        actual_close_date: nil, contact: { name: "Existing", email: "existing@dupco.com" }
      }
    ]

    assert_no_difference "Contact.count" do
      CsvImportExecutionService.new(rows, :proposal, @admin).call
    end
  end

  test "creates contact with placeholder email when email is nil" do
    customer = create(:customer, company_name: "PlaceholderCo")

    rows = [
      {
        row_number: 2, title: "No Email", linkable_company_name: "PlaceholderCo",
        responsible_consultant_name: nil, status: "draft",
        estimated_value: nil, final_value: nil,
        current_document_url: nil, notes: nil, date_asked: nil,
        actual_close_date: nil, contact: { name: "Juan Pérez", email: nil }
      }
    ]

    CsvImportExecutionService.new(rows, :proposal, @admin).call

    contact = customer.contacts.find_by(name: "Juan Pérez")
    assert_not_nil contact
    assert_equal "juan-perez@placeholder.import", contact.email
  end

  # --- Customer type routing ---

  test "skips customer row with customer_type prospect and records error" do
    rows = [ { row_number: 2, company_name: "Prospect Co", country: nil, industry: nil, responsible_consultant_name: nil, last_activity_date: nil, customer_type: :prospect, intention: nil, warnings: [] } ]

    result = CsvImportExecutionService.new(rows, :customer, @admin).call

    assert_equal 0, result[:created_count]
    assert_equal 1, result[:error_count]
    assert_includes result[:errors].first[:messages].first, "Prospect-type"
    assert_nil Customer.find_by(company_name: "Prospect Co")
  end

  test "creates customer with inactive status when customer_type is inactive" do
    rows = [ { row_number: 2, company_name: "Inactive Co", country: nil, industry: nil, responsible_consultant_name: nil, last_activity_date: nil, customer_type: :inactive, intention: nil, warnings: [] } ]

    CsvImportExecutionService.new(rows, :customer, @admin).call

    customer = Customer.find_by(company_name: "Inactive Co")
    assert_not_nil customer
    assert customer.inactive?
  end

  test "creates customer with active status when customer_type is active" do
    rows = [ { row_number: 2, company_name: "Active Co", country: nil, industry: nil, responsible_consultant_name: nil, last_activity_date: nil, customer_type: :active, intention: nil, warnings: [] } ]

    CsvImportExecutionService.new(rows, :customer, @admin).call

    assert Customer.find_by(company_name: "Active Co").active?
  end

  test "creates customer with intention keep" do
    rows = [ { row_number: 2, company_name: "Keep Co", country: nil, industry: nil, responsible_consultant_name: nil, last_activity_date: nil, customer_type: nil, intention: :keep, warnings: [] } ]

    CsvImportExecutionService.new(rows, :customer, @admin).call

    assert_equal "keep", Customer.find_by(company_name: "Keep Co").intention
  end

  test "creates customer with nil intention" do
    rows = [ { row_number: 2, company_name: "No Intent Co", country: nil, industry: nil, responsible_consultant_name: nil, last_activity_date: nil, customer_type: nil, intention: nil, warnings: [] } ]

    CsvImportExecutionService.new(rows, :customer, @admin).call

    assert_nil Customer.find_by(company_name: "No Intent Co").intention
  end

  # --- Proposal nil status ---

  test "proposal row with nil status fails validation and records error" do
    customer = create(:customer, company_name: "StatusNilCo")
    create(:contact, customer: customer, primary: true)

    rows = [
      {
        row_number: 2, title: "No Status Proposal", linkable_company_name: "StatusNilCo",
        responsible_consultant_name: nil, status: nil,
        estimated_value: nil, final_value: nil,
        current_document_url: nil, notes: nil, date_asked: nil,
        actual_close_date: nil, contact: nil
      }
    ]

    result = CsvImportExecutionService.new(rows, :proposal, @admin).call

    assert_equal 0, result[:created_count]
    assert_equal 1, result[:error_count]
    assert_equal 2, result[:errors].first[:row]
  end

  # --- Validation error collection ---

  test "collects validation errors without stopping" do
    rows = [
      { row_number: 2, company_name: "Valid Co", industry: nil, responsible_consultant_name: nil, last_activity_date: nil },
      { row_number: 3, company_name: nil, industry: nil, responsible_consultant_name: nil, last_activity_date: nil }
    ]

    result = CsvImportExecutionService.new(rows, :customer, @admin).call

    assert_equal 1, result[:created_count]
    assert_equal 1, result[:error_count]
    assert_equal 3, result[:errors].first[:row]
  end

  # --- ActivityLog entries ---

  test "creates activity log for imported customers" do
    rows = [ { row_number: 2, company_name: "LogCo", industry: nil, responsible_consultant_name: nil, last_activity_date: nil } ]

    assert_difference "ActivityLog.count" do
      CsvImportExecutionService.new(rows, :customer, @admin).call
    end

    log = ActivityLog.last
    assert_equal "Customer", log.loggable_type
    assert_includes log.content, "LogCo"
  end

  test "creates activity log for imported proposals" do
    customer = create(:customer, company_name: "LogPropCo")
    create(:contact, customer: customer, primary: true)

    rows = [
      {
        row_number: 2, title: "Logged Proposal", linkable_company_name: "LogPropCo",
        responsible_consultant_name: nil, status: "draft",
        estimated_value: nil, final_value: nil,
        current_document_url: nil, notes: nil, date_asked: nil,
        actual_close_date: nil, contact: nil
      }
    ]

    assert_difference "ActivityLog.count" do
      CsvImportExecutionService.new(rows, :proposal, @admin).call
    end
  end
end
