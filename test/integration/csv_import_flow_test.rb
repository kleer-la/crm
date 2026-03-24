require "test_helper"

class CsvImportFlowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in(@admin)
  end

  # 5.1 Full user import flow

  test "full user import flow creates new users and skips existing emails" do
    existing = create(:user, email: "existing@example.com")

    csv = "name,email,role\nAlice Smith,alice@import.com,consultant\nBob Jones,existing@example.com,consultant\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "user", file: file }
    assert_response :success
    assert_includes response.body, "Alice Smith"

    assert_difference "User.count", 1 do
      post admin_imports_path
    end
    assert_response :success

    assert User.exists?(email: "alice@import.com", name: "Alice Smith")
    assert_equal existing.id, User.find_by(email: "existing@example.com").id
    assert_includes response.body, "Created"
    assert_includes response.body, "Skipped"
  end

  # 5.2 Full customer import flow

  test "full customer import flow creates customers without contacts" do
    csv = "CLIENTE\tSector\tResponsables\tÚltimo contacto\nRiveria Corp\tFinance\t\t2024/01/15\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "customer", file: file }
    assert_response :success
    assert_includes response.body, "Riveria Corp"

    assert_difference "Customer.count", 1 do
      assert_no_difference "Contact.count" do
        post admin_imports_path
      end
    end
    assert_response :success

    customer = Customer.find_by(company_name: "Riveria Corp")
    assert_not_nil customer
    assert_equal "active", customer.status
    assert_equal 0, customer.contacts.count
  end

  # 5.3 Full proposal import flow

  test "full proposal import flow creates proposals linked to customers with contacts from Contacto column" do
    customer = create(:customer, company_name: "Nexus Corp")

    csv = "Propuesta\tCliente\tEstado\tContacto\nBig Deal\tNexus Corp\tGanado\tJane Smith <jane@nexus.com>\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "proposal", file: file }
    assert_response :success
    assert_includes response.body, "Big Deal"

    assert_difference "Proposal.count", 1 do
      assert_difference "Contact.count", 1 do
        post admin_imports_path
      end
    end
    assert_response :success

    proposal = Proposal.find_by(title: "Big Deal")
    assert_not_nil proposal
    assert_equal customer, proposal.linkable
    assert_equal "won", proposal.status
    assert_equal "Imported", proposal.win_loss_reason

    contact = customer.contacts.find_by(name: "Jane Smith")
    assert_not_nil contact
    assert_equal "jane@nexus.com", contact.email
  end

  # 5.4 Error scenarios

  test "proposal import with unmatched linkable records an error and shows details" do
    csv = "Propuesta\tCliente\tEstado\nMystery Deal\tUnknown Corp\tGanado\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "proposal", file: file }

    assert_no_difference "Proposal.count" do
      post admin_imports_path
    end
    assert_response :success
    assert_includes response.body, "Unknown Corp"
    assert_includes response.body, "Error Details"
  end

  test "preview with invalid status value redirects with error" do
    csv = "Propuesta\tCliente\tEstado\nBad Deal\tAcme\tArchivedOld\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "proposal", file: file }
    assert_redirected_to new_admin_import_path
    assert_match(/Unknown status/, flash[:alert])
  end

  test "unmatched consultant name falls back to importing admin and import succeeds" do
    create(:customer, company_name: "Zeta Corp")

    csv = "Propuesta\tCliente\tEstado\tResponsable\nFallback Deal\tZeta Corp\tBUN\tNonExistentConsultant\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "proposal", file: file }

    assert_difference "Proposal.count", 1 do
      post admin_imports_path
    end

    proposal = Proposal.find_by(title: "Fallback Deal")
    assert_not_nil proposal
    assert_equal @admin, proposal.responsible_consultant
  end

  test "import page shows existing records warning when data is present" do
    create(:customer)

    get new_admin_import_path
    assert_response :success
    assert_includes response.body, "Existing records detected"
  end

  private

  def fixture_csv(content)
    Rack::Test::UploadedFile.new(
      StringIO.new(content), "text/csv", true, original_filename: "import.csv"
    )
  end
end
