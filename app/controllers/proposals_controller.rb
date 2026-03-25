class ProposalsController < ApplicationController
  include Sortable

  before_action :set_proposal, only: [ :show, :edit, :update, :destroy, :mark_won, :mark_lost, :duplicate, :archive_document ]

  SORT_FIELDS = %i[title status estimated_value date_asked date_sent expected_close_date actual_close_date].freeze

  def index
    @proposals = Proposal.preload(:linkable).includes(:responsible_consultant)
    @proposals = apply_filters(@proposals)
    @proposals = apply_sort(@proposals, allowed_fields: SORT_FIELDS, default_field: :created_at)
  end

  def show
    @document_versions = @proposal.document_versions.order(archived_at: :desc)
  end

  def new
    @proposal = Proposal.new(status: :draft)
    @proposal.linkable_type = params[:linkable_type] if params[:linkable_type].present?
    @proposal.linkable_id = params[:linkable_id] if params[:linkable_id].present?
  end

  def create
    @proposal = Proposal.new(proposal_params)

    if @proposal.save
      redirect_to @proposal, notice: "Proposal was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @proposal.update(proposal_params)
      redirect_to @proposal, notice: "Proposal was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @proposal.destroy
      redirect_to proposals_path, notice: "Proposal was successfully deleted."
    else
      redirect_to @proposal, alert: "Cannot delete proposal with associated tasks."
    end
  end

  def mark_won
    @proposal.assign_attributes(
      status: :won,
      win_loss_reason: params[:proposal][:win_loss_reason]
    )

    if @proposal.save
      redirect_to @proposal, notice: "Proposal marked as Won."
    else
      redirect_to @proposal, alert: @proposal.errors.full_messages.to_sentence
    end
  end

  def mark_lost
    @proposal.assign_attributes(
      status: :lost,
      win_loss_reason: params[:proposal][:win_loss_reason]
    )

    if @proposal.save
      redirect_to @proposal, notice: "Proposal marked as Lost."
    else
      redirect_to @proposal, alert: @proposal.errors.full_messages.to_sentence
    end
  end

  def duplicate
    new_proposal = @proposal.duplicate
    new_proposal.save!
    redirect_to edit_proposal_path(new_proposal), notice: "Proposal duplicated as draft."
  rescue ActiveRecord::RecordInvalid
    redirect_to @proposal, alert: "Failed to duplicate proposal."
  end

  def archive_document
    if @proposal.current_document_url.blank?
      redirect_to @proposal, alert: "No document link to archive."
      return
    end

    @proposal.document_versions.create!(
      label: params[:label].presence || "Archived #{Date.current}",
      url: @proposal.current_document_url,
      archived_by: current_user,
      archived_at: Time.current
    )

    @proposal.update!(current_document_url: params[:new_url])
    redirect_to @proposal, notice: "Document archived and link updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @proposal, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_proposal
    @proposal = Proposal.find(params[:id])
  end

  def proposal_params
    params.require(:proposal).permit(
      :title, :linkable_type, :linkable_id,
      :status, :estimated_value,
      :date_asked, :date_sent, :expected_close_date, :actual_close_date,
      :win_loss_reason, :notes, :current_document_url,
      :responsible_consultant_id,
      collaborating_consultant_ids: []
    )
  end

  def apply_filters(scope)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(responsible_consultant_id: params[:consultant_id]) if params[:consultant_id].present?
    scope = scope.where(linkable_type: params[:linkable_type]) if params[:linkable_type].present?
    scope = scope.where("title ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    scope
  end
end
