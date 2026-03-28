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
    assert_equal "Argentina", row[:country]
    assert_equal "Seguros", row[:industry]
    assert_equal "Andrés J", row[:responsible_consultant_name]
    assert_equal Date.new(2024, 3, 11), row[:last_activity_date]
  end

  test "customer CSV returns nil for blank country" do
    csv = "País facturador\tPaís/es\tSector\tResponsables\tCLIENTE\tTipo de cliente\tEstrategia (KARE)\tÚltimo contacto\tPróximo Contacto\tLog contacto\tResumen del cliente\n" \
          "Uruguay\t\tSeguros\tAndrés J\tSan cristobal\tNuevo facturado\t\t2024/03/11\t\t\t\n"
    result = CsvImportParserService.new(csv, :customer).call

    assert_nil result[:rows].first[:country]
  end

  test "customer CSV ignores billing country column" do
    csv = "País facturador\tPaís/es\tSector\tResponsables\tCLIENTE\tTipo de cliente\tEstrategia (KARE)\tÚltimo contacto\tPróximo Contacto\tLog contacto\tResumen del cliente\n" \
          "Uruguay\tArgentina\tSeguros\tAndrés J\tSan cristobal\tNuevo facturado\t\t2024/03/11\t\t\t\n"
    result = CsvImportParserService.new(csv, :customer).call

    row = result[:rows].first
    assert_equal "Argentina", row[:country]
    assert_not_includes row.keys, :billing_country
    assert_not_includes row.values, "Uruguay"
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

  # Prospect CSV

  test "parses valid prospect CSV" do
    csv = "CLIENTE\tContacto\tEmail\tTeléfono\tPaís/es\tSector\tResponsables\tFuente\tÚltimo contacto\tFecha inicio\n" \
          "IConstruye\tJuan López\tjlopez@iconstruye.com\t+598 99 123 456\tUruguay\tConstrucción\tPablo Lis\tReferido\t2024/03/11\t2024/01/01\n"
    result = CsvImportParserService.new(csv, :prospect).call

    assert_equal 1, result[:rows].size
    row = result[:rows].first
    assert_equal "IConstruye", row[:company_name]
    assert_equal "Juan López", row[:primary_contact_name]
    assert_equal "jlopez@iconstruye.com", row[:primary_contact_email]
    assert_equal "+598 99 123 456", row[:primary_contact_phone]
    assert_equal "Uruguay", row[:country]
    assert_equal "Construcción", row[:industry]
    assert_equal "Pablo Lis", row[:responsible_consultant_name]
    assert_equal :referral, row[:source]
    assert_equal Date.new(2024, 3, 11), row[:last_activity_date]
    assert_equal Date.new(2024, 1, 1), row[:date_added]
    assert_nil row[:source_raw]
  end

  test "prospect Contacto column with Name <email> format extracts both name and email" do
    csv = "CLIENTE\tContacto\n" \
          "Acme\tJuan López <jlopez@acme.com>\n"
    result = CsvImportParserService.new(csv, :prospect).call

    row = result[:rows].first
    assert_equal "Juan López", row[:primary_contact_name]
    assert_equal "jlopez@acme.com", row[:primary_contact_email]
  end

  test "prospect separate Email column takes priority over email in Contacto" do
    csv = "CLIENTE\tContacto\tEmail\n" \
          "Acme\tJuan López <jlopez@acme.com>\texplicit@acme.com\n"
    result = CsvImportParserService.new(csv, :prospect).call

    row = result[:rows].first
    assert_equal "Juan López", row[:primary_contact_name]
    assert_equal "explicit@acme.com", row[:primary_contact_email]
  end

  test "prospect CSV with missing optional columns returns nil for those fields" do
    csv = "CLIENTE\tContacto\tEmail\n" \
          "DPWorld\tMaria Gómez\tmgomez@dpworld.com\n"
    result = CsvImportParserService.new(csv, :prospect).call

    row = result[:rows].first
    assert_equal "DPWorld", row[:company_name]
    assert_nil row[:country]
    assert_nil row[:source]
    assert_nil row[:last_activity_date]
    assert_nil row[:date_added]
  end

  test "maps all PROSPECT_SOURCE_MAPPING entries" do
    {
      "Referido"  => :referral,
      "Referral"  => :referral,
      "Inbound"   => :inbound,
      "Outbound"  => :outbound,
      "Evento"    => :event,
      "Event"     => :event,
      "Otro"      => :other,
      "Other"     => :other
    }.each do |spanish, expected|
      csv = "CLIENTE\tContacto\tEmail\tFuente\n" \
            "Acme\tContact\tcontact@acme.com\t#{spanish}\n"
      result = CsvImportParserService.new(csv, :prospect).call
      assert_equal expected, result[:rows].first[:source], "Expected #{spanish} → #{expected}"
    end
  end

  test "unknown Fuente returns nil source" do
    csv = "CLIENTE\tContacto\tEmail\tFuente\n" \
          "Acme\tContact\tcontact@acme.com\tDesconocido\n"
    result = CsvImportParserService.new(csv, :prospect).call
    assert_nil result[:rows].first[:source]
  end

  test "raises error for missing required prospect header" do
    csv = "Fuente\n" \
          "Referido\n"

    error = assert_raises(CsvImportParserService::ParseError) do
      CsvImportParserService.new(csv, :prospect).call
    end
    assert_includes error.message, "CLIENTE"
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

  test "unknown status value returns nil status and adds warning" do
    csv = "Propuesta\tCliente\tEstado\n" \
          "Test\tAcme\tDesconocido\n"

    result = CsvImportParserService.new(csv, :proposal).call
    row = result[:rows].first
    assert_nil row[:status]
    assert_includes row[:warnings], "Desconocido"
  end

  test "returns nil status for blank estado" do
    csv = "Propuesta\tCliente\tEstado\n" \
          "Test\tAcme\t\n"
    result = CsvImportParserService.new(csv, :proposal).call
    row = result[:rows].first
    assert_nil row[:status]
    assert_empty row[:warnings]
  end

  test "maps new proposal status synonyms" do
    {
      "En espera" => "under_review",
      "Revisión" => "under_review",
      "Aprobado" => "won",
      "Rechazado" => "lost",
      "Cancelado" => "cancelled"
    }.each do |spanish, english|
      csv = "Propuesta\tCliente\tEstado\n" \
            "Test\tAcme\t#{spanish}\n"
      result = CsvImportParserService.new(csv, :proposal).call
      assert_equal english, result[:rows].first[:status], "Expected #{spanish} → #{english}"
    end
  end

  test "one unknown-status row and one valid row both parse without abort" do
    csv = "Propuesta\tCliente\tEstado\n" \
          "Test1\tAcme\tDesconocido\n" \
          "Test2\tAcme\tGanado\n"
    result = CsvImportParserService.new(csv, :proposal).call
    assert_equal 2, result[:rows].size
    assert_nil result[:rows][0][:status]
    assert_includes result[:rows][0][:warnings], "Desconocido"
    assert_equal "won", result[:rows][1][:status]
    assert_empty result[:rows][1][:warnings]
  end

  # Customer type mapping

  test "maps all CUSTOMER_TYPE_MAPPING entries to correct customer_type" do
    {
      "Potencial"                      => :prospect,
      "Prospecto"                      => :prospect,
      "Cliente activo"                 => :active,
      "Nuevo facturado"                => :active,
      "Cliente inactivo por recuperar" => :inactive,
      "Cliente recuperado"             => :active,
      "No contesta"                    => :inactive,
      "Descartar"                      => :inactive
    }.each do |spanish, expected|
      csv = "CLIENTE\tTipo de cliente\n" \
            "Acme\t#{spanish}\n"
      result = CsvImportParserService.new(csv, :customer).call
      assert_equal expected, result[:rows].first[:customer_type], "Expected #{spanish} → #{expected}"
    end
  end

  test "blank Tipo de cliente leaves customer_type as nil" do
    csv = "CLIENTE\tTipo de cliente\n" \
          "Acme\t\n"
    result = CsvImportParserService.new(csv, :customer).call
    assert_nil result[:rows].first[:customer_type]
  end

  test "unknown Tipo de cliente sets customer_type to nil and adds warning" do
    csv = "CLIENTE\tTipo de cliente\n" \
          "Acme\tDesconocido\n"
    result = CsvImportParserService.new(csv, :customer).call
    row = result[:rows].first
    assert_nil row[:customer_type]
    assert_includes row[:warnings], "Desconocido"
  end

  # Customer strategy mapping

  test "maps all CUSTOMER_INTENTION_MAPPING entries to correct strategy" do
    {
      "Mantener"        => :keep,
      "Captar o atraer" => :attract,
      "Recuperar"       => :recapture,
      "Expandir"        => :expand
    }.each do |spanish, expected|
      csv = "CLIENTE\tEstrategia (KARE)\n" \
            "Acme\t#{spanish}\n"
      result = CsvImportParserService.new(csv, :customer).call
      assert_equal expected, result[:rows].first[:strategy], "Expected #{spanish} → #{expected}"
    end
  end

  test "blank Estrategia (KARE) returns nil strategy with no warning" do
    csv = "CLIENTE\tEstrategia (KARE)\n" \
          "Acme\t\n"
    result = CsvImportParserService.new(csv, :customer).call
    row = result[:rows].first
    assert_nil row[:strategy]
    assert_empty row[:warnings]
  end

  test "unknown Estrategia (KARE) returns nil strategy with no warning" do
    csv = "CLIENTE\tEstrategia (KARE)\n" \
          "Acme\tAlgoRaro\n"
    result = CsvImportParserService.new(csv, :customer).call
    row = result[:rows].first
    assert_nil row[:strategy]
    assert_empty row[:warnings]
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
