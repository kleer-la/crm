class IngestWebContactJob < ApplicationJob
  queue_as :default

  INTAKE_EMAIL = "info@kleer.la"

  def perform(contact_payload)
    intake_user = User.find_by!(email: INTAKE_EMAIL)

    ActiveRecord::Base.transaction do
      linkable = resolve_linkable(contact_payload["company"]) || create_prospect!(contact_payload, intake_user)
      create_draft_proposal!(linkable, contact_payload, intake_user)
      log_inbound_touchpoint!(linkable, contact_payload)
    end
  end

  private

  def resolve_linkable(company)
    return nil if company.blank?

    # Duplicates CsvImportExecutionService#find_linkable logic.
    # Extract to a shared LinkableMatcher when a third caller appears.
    linkable = Customer.where("company_name ILIKE ?", company).first
    linkable ||= Prospect.where("company_name ILIKE ?", company).first

    unless linkable
      linkable = Customer.search_by_name(company).first
      linkable ||= Prospect.search_by_name(company).first
    end

    linkable
  end

  def create_prospect!(payload, intake_user)
    Prospect.create!(
      company_name: payload["company"],
      primary_contact_name: payload["name"],
      primary_contact_email: payload["email"],
      source: :inbound,
      status: :new_prospect,
      responsible_consultant: intake_user,
      date_added: Date.current,
      last_activity_date: Date.current
    )
  end

  def create_draft_proposal!(linkable, payload, intake_user)
    company = payload["company"]
    Proposal.create!(
      title: "Inbound web lead — #{company}",
      description: "Lead captured from the marketing site. See activity log for the original message.",
      status: :draft,
      notes: payload["context"],
      linkable: linkable,
      responsible_consultant: intake_user
    )
  end

  def log_inbound_touchpoint!(linkable, payload)
    message = payload["message"].presence || "No message provided"
    linkable.log_touchpoint(
      touchpoint_type: :other,
      content: "Inbound web message: #{message}",
      user: nil
    )
  end
end
