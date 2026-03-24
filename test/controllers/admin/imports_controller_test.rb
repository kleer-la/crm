require "test_helper"

class Admin::ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in(@admin)
  end

  # Access control

  test "admin can access import page" do
    get new_admin_import_path
    assert_response :success
    assert_includes response.body, "Import Data"
  end

  test "non-admin is rejected" do
    consultant = create(:user)
    sign_in(consultant)
    get new_admin_import_path
    assert_redirected_to root_path
  end

  # User upload flow

  test "preview with valid user CSV" do
    csv = "name,email,role\nAlice,alice@example.com,consultant\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "user", file: file }
    assert_response :success
    assert_includes response.body, "Alice"
  end

  test "preview with valid customer CSV" do
    csv = "CLIENTE\tSector\nAcme Corp\tTech\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "customer", file: file }
    assert_response :success
    assert_includes response.body, "Acme Corp"
  end

  test "preview with valid proposal CSV" do
    csv = "Propuesta\tCliente\tEstado\nTest Proposal\tAcme\tGanado\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "proposal", file: file }
    assert_response :success
    assert_includes response.body, "Test Proposal"
  end

  # Invalid uploads

  test "preview rejects non-CSV file" do
    file = Rack::Test::UploadedFile.new(
      StringIO.new("not a csv"), "text/plain", true, original_filename: "data.txt"
    )

    post preview_admin_imports_path, params: { record_type: "user", file: file }
    assert_redirected_to new_admin_import_path
    assert_match(/CSV/, flash[:alert])
  end

  test "preview rejects missing file" do
    post preview_admin_imports_path, params: { record_type: "user" }
    assert_redirected_to new_admin_import_path
    assert_match(/select a file/, flash[:alert])
  end

  test "preview rejects missing required headers" do
    csv = "wrong_header\ndata\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "user", file: file }
    assert_redirected_to new_admin_import_path
    assert_match(/Missing required headers/, flash[:alert])
  end

  # Successful import

  test "create imports users successfully" do
    csv = "name,email,role\nAlice,alice@example.com,consultant\n"
    file = fixture_csv(csv)

    # First preview to populate session
    post preview_admin_imports_path, params: { record_type: "user", file: file }
    assert_response :success

    assert_difference "User.count", 1 do
      post admin_imports_path
    end
    assert_response :success
    assert_includes response.body, "Created"
  end

  test "create imports customers successfully" do
    csv = "CLIENTE\tSector\nImported Co\tTech\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "customer", file: file }

    assert_difference "Customer.count", 1 do
      post admin_imports_path
    end
    assert_response :success
    assert_includes response.body, "Created"
  end

  test "create shows errors for invalid data" do
    customer = create(:customer, company_name: "Existing Co")
    create(:contact, customer: customer, primary: true)

    csv = "Propuesta\tCliente\tEstado\nTest\tNonExistent\tGanado\n"
    file = fixture_csv(csv)

    post preview_admin_imports_path, params: { record_type: "proposal", file: file }

    post admin_imports_path
    assert_response :success
    assert_includes response.body, "Errors"
  end

  test "create redirects if no session data" do
    post admin_imports_path
    assert_redirected_to new_admin_import_path
    assert_match(/No import data/, flash[:alert])
  end

  private

  def fixture_csv(content)
    Rack::Test::UploadedFile.new(
      StringIO.new(content), "text/csv", true, original_filename: "import.csv"
    )
  end
end
