class CsvImportParserService
  class ParseError < StandardError; end

  HEADER_MAPPINGS = {
    user: {
      "name" => :name,
      "email" => :email,
      "role" => :role
    },
    prospect: {
      "CLIENTE" => :company_name,
      "País/es" => :country,
      "Sector" => :industry,
      "Responsables" => :responsible_consultant_name,
      "Contacto" => :primary_contact_name,
      "Email" => :primary_contact_email,
      "Teléfono" => :primary_contact_phone,
      "Fuente" => :source_raw,
      "Último contacto" => :last_activity_date,
      "Fecha inicio" => :date_added
    },
    customer: {
      "CLIENTE" => :company_name,
      "País/es" => :country,
      "Sector" => :industry,
      "Responsables" => :responsible_consultant_name,
      "Tipo de cliente" => :customer_type_raw,
      "Estrategia (KARE)" => :strategy_raw,
      "Último contacto" => :last_activity_date
    },
    proposal: {
      "Propuesta" => :title,
      "Cliente" => :linkable_company_name,
      "Responsable" => :responsible_consultant_name,
      "Estado" => :status_raw,
      "$ Oportunidad" => :estimated_value,
      "Enlace Propuesta" => :current_document_url,
      "Comentarios" => :notes,
      "Fecha del pedido" => :date_asked,
      "Valor factura" => :final_value,
      "Fecha de factura" => :actual_close_date,
      "Contacto" => :contact_raw
    }
  }.freeze

  REQUIRED_HEADERS = {
    user: [ "name", "email" ],
    prospect: [ "CLIENTE" ],
    customer: [ "CLIENTE" ],
    proposal: [ "Propuesta", "Cliente" ]
  }.freeze

  STATUS_MAPPING = {
    "BUN" => "draft",
    "Entender" => "draft",
    "Presupuestar" => "draft",
    "Entregada/WIP" => "sent",
    "Confirmado" => "under_review",
    "Ganado" => "won",
    "Perdido" => "lost",
    "No por ahora" => "lost",
    "Declinamos" => "cancelled",
    "No contesta" => "lost",
    "En espera" => "under_review",
    "Revisión" => "under_review",
    "Aprobado" => "won",
    "Rechazado" => "lost",
    "Cancelado" => "cancelled"
  }.freeze

  CUSTOMER_TYPE_MAPPING = {
    "Potencial"                      => :prospect,
    "Prospecto"                      => :prospect,
    "Cliente activo"                 => :active,
    "Nuevo facturado"                => :active,
    "Cliente inactivo por recuperar" => :inactive,
    "Cliente recuperado"             => :active,
    "No contesta"                    => :inactive,
    "Descartar"                      => :inactive
  }.freeze

  PROSPECT_SOURCE_MAPPING = {
    "Referido"        => :referral,
    "Referral"        => :referral,
    "Inbound"         => :inbound,
    "Outbound"        => :outbound,
    "Evento"          => :event,
    "Event"           => :event,
    "Otro"            => :other,
    "Other"           => :other
  }.freeze

  CUSTOMER_INTENTION_MAPPING = {
    "Mantener"        => :keep,
    "Captar o atraer" => :attract,
    "Recuperar"       => :recapture,
    "Expandir"        => :expand
  }.freeze

  MONETARY_FIELDS = %i[estimated_value final_value].freeze
  DATE_FIELDS = %i[last_activity_date date_asked actual_close_date date_added].freeze

  def initialize(csv_content, record_type)
    @csv_content = strip_bom(csv_content)
    @record_type = record_type.to_sym
    @mapping = HEADER_MAPPINGS.fetch(@record_type)
  end

  def call
    validate_content!
    parsed = parse_csv
    validate_headers!(parsed.headers)

    rows = parsed.map.with_index(2) do |csv_row, row_number|
      mapped = map_row(csv_row)
      clean_values!(mapped)
      { row_number: row_number }.merge(mapped)
    end

    { headers: parsed.headers, rows: rows }
  end

  private

  def strip_bom(content)
    content.sub(/\A\xEF\xBB\xBF/, "")
  end

  def validate_content!
    raise ParseError, "File is empty" if @csv_content.blank?
  end

  def parse_csv
    separator = detect_separator
    table = CSV.parse(@csv_content, headers: true, liberal_parsing: true, col_sep: separator)
    raise ParseError, "File has no data rows" if table.empty?
    table
  end

  def detect_separator
    first_line = @csv_content.lines.first.to_s
    first_line.include?("\t") ? "\t" : ","
  end

  def validate_headers!(headers)
    required = REQUIRED_HEADERS.fetch(@record_type)
    missing = required - headers.map(&:to_s).map(&:strip)
    if missing.any?
      raise ParseError, "Missing required headers: #{missing.join(', ')}"
    end
  end

  def map_row(csv_row)
    result = {}
    @mapping.each do |header, field|
      value = csv_row[header]
      result[field] = value&.strip
    end
    result
  end

  def clean_values!(row)
    row[:warnings] ||= []

    MONETARY_FIELDS.each do |field|
      row[field] = parse_monetary(row[field]) if row.key?(field)
    end

    DATE_FIELDS.each do |field|
      row[field] = parse_date(row[field]) if row.key?(field)
    end

    if row.key?(:status_raw)
      row[:status] = map_status(row, row.delete(:status_raw))
    end

    if row.key?(:contact_raw)
      row[:contact] = parse_contact(row.delete(:contact_raw))
    end

    if row.key?(:customer_type_raw)
      raw = row.delete(:customer_type_raw)
      if raw.blank?
        row[:customer_type] = nil
      elsif CUSTOMER_TYPE_MAPPING.key?(raw)
        row[:customer_type] = CUSTOMER_TYPE_MAPPING[raw]
      else
        row[:customer_type] = nil
        row[:warnings] << raw
      end
    end

    if row.key?(:strategy_raw)
      raw = row.delete(:strategy_raw)
      row[:strategy] = raw.blank? ? nil : CUSTOMER_INTENTION_MAPPING[raw]
    end

    if row.key?(:source_raw)
      raw = row.delete(:source_raw)
      row[:source] = raw.blank? ? nil : PROSPECT_SOURCE_MAPPING[raw]
    end
  end

  def parse_monetary(value)
    return nil if value.blank?
    cleaned = value.gsub(/[$,]/, "")
    return nil if cleaned.blank?
    unless cleaned.match?(/\A-?\d+(\.\d+)?\z/)
      raise ParseError, "Invalid monetary value: #{value}"
    end
    BigDecimal(cleaned)
  end

  def parse_date(value)
    return nil if value.blank?
    Date.parse(value.tr("/", "-"))
  rescue Date::Error
    raise ParseError, "Invalid date: #{value}"
  end

  def map_status(row, value)
    return nil if value.blank?
    if STATUS_MAPPING.key?(value)
      STATUS_MAPPING[value]
    else
      row[:warnings] << value
      nil
    end
  end

  def parse_contact(value)
    return nil if value.blank?
    if value =~ /\A(.+?)\s*<([^>]+)>\z/
      { name: $1.strip, email: $2.strip }
    else
      { name: value.strip, email: nil }
    end
  end
end
