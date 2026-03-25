require "test_helper"

class CsvImportParserServiceTest < ActiveSupport::TestCase
  # User CSV

  test "parses valid user CSV" do
    csv = "name,email,role\nAlice,alice@example.com,admin\nBob,bob@example.com,consultant\n"
    result = CsvImportParserService.new(csv, :user).call

    assert_equal %w[name email role], result[:headers]
    assert_equal 2, result[:rows].size

    row = result[:rows].first
    assert_equal 2, row[:row_number]
    assert_equal "Alice", row[:name]
    assert_equal "alice@example.com", row[:email]
    assert_equal "admin", row[:role]
  end

  test "user CSV defaults role to nil when blank" do
    csv = "name,email,role\nAlice,alice@example.com,\n"
    result = CsvImportParserService.new(csv, :user).call

    assert_nil result[:rows].first[:role]
  end

  # Customer CSV

  test "parses valid customer CSV" do
    csv = "País facturador\tPaís/es\tSector\tResponsables\tCLIENTE\tTipo de cliente\tEstrategia (KARE)\tÚltimo contacto\tPróximo Contacto\tLog contacto\tResumen del cliente\n" \
          "Argentina\tArgentina\tSeguros\tAndrés J\tSan cristobal\tNuevo facturado\t\t2024/03/11\t\t\t\n"
    result = CsvImportParserService.new(csv, :customer).call

    assert_equal 1, result[:rows].size
    row = result[:rows].first
    assert_equal "San cristobal", row[:company_name]
    assert_equal "Seguros", row[:industry]
    assert_equal "Andrés J", row[:responsible_consultant_name]
    assert_equal Date.new(2024, 3, 11), row[:last_activity_date]
  end

  # Proposal CSV

  test "parses valid proposal CSV" do
    csv = "Estado\tFecha del pedido\tCliente\tResponsable\tEquipo preventa\tContacto\tPropuesta\tOrigen de la oportunidad\tTipo de Servicio\tProbabilidad de Venta\t$ Oportunidad\tClasificación\tFecha Últ. Contacto\tFecha último ping\tProx Contacto\tValor factura\tFecha de factura\tPaís que Factura\tEnlace Propuesta\tComentarios\n" \
          "Perdido\t2024/03/11\tUTE UY\tPablo Lis\tPablo Lis\tLucila Sasías <lsasias@ute.com.uy>\tCurso Agilidad y Scrum\t\tCapacitación\t(0 - 20)%\t$2,500\tLata\t2024/04/17\t\t\t\t\t\tUruguay\t\t\n"
    result = CsvImportParserService.new(csv, :proposal).call

    assert_equal 1, result[:rows].size
    row = result[:rows].first
    assert_equal "Curso Agilidad y Scrum", row[:title]
    assert_equal "UTE UY", row[:linkable_company_name]
    assert_equal "Pablo Lis", row[:responsible_consultant_name]
    assert_equal "lost", row[:status]
    assert_equal BigDecimal("2500"), row[:estimated_value]
    assert_equal Date.new(2024, 3, 11), row[:date_asked]
    assert_equal({ name: "Lucila Sasías", email: "lsasias@ute.com.uy" }, row[:contact])
    assert_nil row[:status_raw]
    assert_nil row[:contact_raw]
  end

  # Header validation

  test "raises error for missing required customer header" do
    csv = "Sector\tResponsables\n" \
          "Seguros\tAndrés\n"

    error = assert_raises(CsvImportParserService::ParseError) do
      CsvImportParserService.new(csv, :customer).call
    end
    assert_includes error.message, "CLIENTE"
  end

  test "raises error for missing required proposal headers" do
    csv = "Estado\t$ Oportunidad\n" \
          "Perdido\t$100\n"

    error = assert_raises(CsvImportParserService::ParseError) do
      CsvImportParserService.new(csv, :proposal).call
    end
    assert_includes error.message, "Propuesta"
    assert_includes error.message, "Cliente"
  end

  test "raises error for missing required user headers" do
    csv = "role\nadmin\n"

    error = assert_raises(CsvImportParserService::ParseError) do
      CsvImportParserService.new(csv, :user).call
    end
    assert_includes error.message, "name"
    assert_includes error.message, "email"
  end

  # Empty file

  test "raises error for empty content" do
    error = assert_raises(CsvImportParserService::ParseError) do
      CsvImportParserService.new("", :customer).call
    end
    assert_equal "File is empty", error.message
  end

  test "raises error for headers only with no data rows" do
    csv = "CLIENTE\tSector\n"

    error = assert_raises(CsvImportParserService::ParseError) do
      CsvImportParserService.new(csv, :customer).call
    end
    assert_equal "File has no data rows", error.message
  end

  # Monetary value cleanup

  test "parses monetary values with dollar sign and commas" do
    csv = "Propuesta\tCliente\t$ Oportunidad\tValor factura\n" \
          "Test\tAcme\t$1,234.56\t$2,500\n"
    result = CsvImportParserService.new(csv, :proposal).call

    row = result[:rows].first
    assert_equal BigDecimal("1234.56"), row[:estimated_value]
    assert_equal BigDecimal("2500"), row[:final_value]
  end

  test "parses monetary values without formatting" do
    csv = "Propuesta\tCliente\t$ Oportunidad\n" \
          "Test\tAcme\t1234.56\n"
    result = CsvImportParserService.new(csv, :proposal).call

    assert_equal BigDecimal("1234.56"), result[:rows].first[:estimated_value]
  end

  test "returns nil for blank monetary values" do
    csv = "Propuesta\tCliente\t$ Oportunidad\n" \
          "Test\tAcme\t\n"
    result = CsvImportParserService.new(csv, :proposal).call

    assert_nil result[:rows].first[:estimated_value]
  end

  test "raises error for non-numeric monetary values" do
    csv = "Propuesta\tCliente\t$ Oportunidad\n" \
          "Test\tAcme\tTBD\n"

    error = assert_raises(CsvImportParserService::ParseError) do
      CsvImportParserService.new(csv, :proposal).call
    end
    assert_includes error.message, "Invalid monetary value"
  end

  # Date parsing

  test "parses dates in YYYY/MM/DD format" do
    csv = "Propuesta\tCliente\tFecha del pedido\n" \
          "Test\tAcme\t2024/03/11\n"
    result = CsvImportParserService.new(csv, :proposal).call

    assert_equal Date.new(2024, 3, 11), result[:rows].first[:date_asked]
  end

  test "returns nil for blank dates" do
    csv = "Propuesta\tCliente\tFecha del pedido\n" \
          "Test\tAcme\t\n"
    result = CsvImportParserService.new(csv, :proposal).call

    assert_nil result[:rows].first[:date_asked]
  end

  test "raises error for invalid dates" do
    csv = "Propuesta\tCliente\tFecha del pedido\n" \
          "Test\tAcme\tnot-a-date\n"

    error = assert_raises(CsvImportParserService::ParseError) do
      CsvImportParserService.new(csv, :proposal).call
    end
    assert_includes error.message, "Invalid date"
  end

  # Status mapping

  test "maps all known status values" do
    expected = {
      "BUN" => "draft", "Entender" => "draft", "Presupuestar" => "draft",
      "Entregada/WIP" => "sent", "Confirmado" => "under_review",
      "Ganado" => "won", "Perdido" => "lost", "No por ahora" => "lost",
      "Declinamos" => "cancelled", "No contesta" => "lost"
    }

    expected.each do |spanish, english|
      csv = "Propuesta\tCliente\tEstado\n" \
            "Test\tAcme\t#{spanish}\n"
      result = CsvImportParserService.new(csv, :proposal).call
      assert_equal english, result[:rows].first[:status], "Expected #{spanish} → #{english}"
    end
  end

  test "raises error for unknown status value" do
    csv = "Propuesta\tCliente\tEstado\n" \
          "Test\tAcme\tDesconocido\n"

    error = assert_raises(CsvImportParserService::ParseError) do
      CsvImportParserService.new(csv, :proposal).call
    end
    assert_includes error.message, "Unknown status"
  end

  test "returns nil status for blank estado" do
    csv = "Propuesta\tCliente\tEstado\n" \
          "Test\tAcme\t\n"
    result = CsvImportParserService.new(csv, :proposal).call

    assert_nil result[:rows].first[:status]
  end

  # Contacto parsing

  test "parses contact with name and email" do
    csv = "Propuesta\tCliente\tContacto\n" \
          "Test\tAcme\tLucila Sasías <lsasias@ute.com.uy>\n"
    result = CsvImportParserService.new(csv, :proposal).call

    contact = result[:rows].first[:contact]
    assert_equal "Lucila Sasías", contact[:name]
    assert_equal "lsasias@ute.com.uy", contact[:email]
  end

  test "parses contact with name only" do
    csv = "Propuesta\tCliente\tContacto\n" \
          "Test\tAcme\tJuan Pérez\n"
    result = CsvImportParserService.new(csv, :proposal).call

    contact = result[:rows].first[:contact]
    assert_equal "Juan Pérez", contact[:name]
    assert_nil contact[:email]
  end

  test "returns nil contact for blank contacto" do
    csv = "Propuesta\tCliente\tContacto\n" \
          "Test\tAcme\t\n"
    result = CsvImportParserService.new(csv, :proposal).call

    assert_nil result[:rows].first[:contact]
  end

  # UTF-8 BOM handling

  test "handles UTF-8 BOM in CSV content" do
    csv = "\xEF\xBB\xBFname,email,role\nAlice,alice@example.com,admin\n"
    result = CsvImportParserService.new(csv, :user).call

    assert_equal 1, result[:rows].size
    assert_equal "Alice", result[:rows].first[:name]
  end

  # Whitespace stripping

  test "strips whitespace from values" do
    csv = "name,email,role\n  Alice  , alice@example.com , admin \n"
    result = CsvImportParserService.new(csv, :user).call

    row = result[:rows].first
    assert_equal "Alice", row[:name]
    assert_equal "alice@example.com", row[:email]
    assert_equal "admin", row[:role]
  end
end
