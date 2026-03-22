class ConvertProspectService
  class ConversionError < StandardError; end

  def initialize(prospect, current_user)
    @prospect = prospect
    @current_user = current_user
  end

  def call
    validate!

    ActiveRecord::Base.transaction do
      mark_prospect_converting
      customer = create_customer
      relink_proposals(customer)
      relink_tasks(customer)
      link_prospect_to_customer(customer)
      customer
    end
  end

  private

  def validate!
    raise ConversionError, "Prospect has already been converted" if @prospect.converted?
    raise ConversionError, "Cannot convert a disqualified prospect" if @prospect.disqualified?
  end

  def create_customer
    Customer.create!(
      company_name: @prospect.company_name,
      industry: @prospect.industry,
      status: :active,
      responsible_consultant: @prospect.responsible_consultant,
      date_became_customer: Date.current,
      last_activity_date: Date.current,
      total_revenue: 0
    )
  end

  def relink_proposals(customer)
    @prospect.proposals.find_each do |proposal|
      proposal.update!(linkable: customer)
    end
  end

  def relink_tasks(customer)
    @prospect.tasks.find_each do |task|
      task.update!(linkable: customer)
    end
  end

  def mark_prospect_converting
    @prospect.update!(status: :converted)
  end

  def link_prospect_to_customer(customer)
    @prospect.update!(converted_customer: customer)
  end
end
