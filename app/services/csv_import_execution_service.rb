class CsvImportExecutionService
  def initialize(rows, record_type, importing_user)
    @rows = rows
    @record_type = record_type.to_sym
    @importing_user = importing_user
    @created_count = 0
    @skipped_count = 0
    @errors = []
  end

  def call
    @rows.each do |row|
      import_row(row)
    end

    { created_count: @created_count, skipped_count: @skipped_count, error_count: @errors.size, errors: @errors }
  end

  private

  def import_row(row)
    case @record_type
    when :user then import_user(row)
    when :customer then import_customer(row)
    when :proposal then import_proposal(row)
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << { row: row[:row_number], messages: e.record.errors.full_messages }
  end

  # --- User import ---

  def import_user(row)
    if User.exists?(email: row[:email])
      @skipped_count += 1
      return
    end

    role = row[:role].presence || "consultant"
    User.create!(
      name: row[:name],
      email: row[:email],
      role: role,
      active: true
    )
    @created_count += 1
  end

  # --- Customer import ---

  def import_customer(row)
    customer_type = row[:customer_type]

    if customer_type == :prospect
      log_error(row[:row_number], "'#{row[:company_name]}' is a Prospect-type account ('Potencial'/'Prospecto') and must be imported via the Prospects CSV (contact data required)")
      return
    end

    if row[:warnings]&.any?
      log_error(row[:row_number], "Unknown 'Tipo de cliente' value: #{row[:warnings].join(', ')}")
      return
    end

    consultant = find_consultant(row[:responsible_consultant_name])
    historical_date = row[:last_activity_date]
    status = customer_type || :active

    customer = Customer.create!(
      company_name: row[:company_name],
      country: row[:country],
      industry: row[:industry],
      status: status,
      strategy: row[:strategy],
      responsible_consultant: consultant,
      date_became_customer: Date.current,
      last_activity_date: historical_date || Date.current,
      total_revenue: 0
    )
    # Restore historical dates — the log_creation callback overwrites last_activity_date with Time.current
    # Both are cleared to nil if not present in the CSV
    customer.update_column(:last_activity_date, historical_date)
    customer.update_column(:date_became_customer, nil)
    @created_count += 1
  end

  # --- Proposal import ---

  def import_proposal(row)
    linkable = find_linkable(row[:linkable_company_name], row[:row_number])
    return unless linkable

    if row[:status].nil?
      log_error(row[:row_number], "Row #{row[:row_number]}: missing or unrecognised proposal status")
      return
    end

    consultant = find_consultant(row[:responsible_consultant_name])
    status = row[:status]

    Proposal.create!(
      title: row[:title],
      linkable: linkable,
      responsible_consultant: consultant,
      status: status,
      estimated_value: row[:estimated_value],
      final_value: row[:final_value],
      current_document_url: valid_url(row[:current_document_url]),
      notes: row[:notes],
      date_asked: row[:date_asked],
      actual_close_date: row[:actual_close_date],
      win_loss_reason: win_loss_reason_for(status)
    )

    extract_contact(linkable, row[:contact]) if row[:contact] && linkable.is_a?(Customer)
    @created_count += 1
  end

  # --- Consultant matching ---

  def find_consultant(name)
    return @importing_user if name.blank?

    # Exact match
    user = User.find_by(name: name)
    return user if user

    # Partial ILIKE match
    user = User.where("name ILIKE ?", "%#{name}%").first
    return user if user

    # Fallback to importing admin
    @importing_user
  end

  # --- Linkable matching ---

  def find_linkable(company_name, row_number)
    return log_error(row_number, "Missing company name") if company_name.blank?

    # 1. Exact case-insensitive match
    linkable = Customer.where("company_name ILIKE ?", company_name).first
    linkable ||= Prospect.where("company_name ILIKE ?", company_name).first

    # 2. Fuzzy trigram match — handles names written differently (e.g. "UTE" vs "UTE UY")
    unless linkable
      linkable = Customer.search_by_name(company_name).first
      linkable ||= Prospect.search_by_name(company_name).first
    end

    unless linkable
      log_error(row_number, "No matching Customer or Prospect found for '#{company_name}'")
      return nil
    end

    linkable
  end

  # --- Contact extraction ---

  def extract_contact(customer, contact_data)
    return if contact_data[:name].blank?

    if contact_data[:email].present?
      contact = customer.contacts.find_by(email: contact_data[:email])
    end
    contact ||= customer.contacts.find_by(name: contact_data[:name])

    unless contact
      is_first = customer.contacts.empty?
      customer.contacts.create!(
        name: contact_data[:name],
        email: contact_data[:email] || "#{contact_data[:name].parameterize}@placeholder.import",
        primary: is_first
      )
    end
  end

  def win_loss_reason_for(status)
    %w[won lost].include?(status) ? "Imported" : nil
  end

  def valid_url(value)
    url = value.presence
    return nil unless url
    url if url.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
  end

  def log_error(row_number, message)
    @errors << { row: row_number, messages: [ message ] }
    nil
  end
end
