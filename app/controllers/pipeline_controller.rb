class PipelineController < ApplicationController
  def index
    @prospects = active_prospects
    @proposals = open_proposals

    @prospects = apply_prospect_filters(@prospects)
    @proposals = apply_proposal_filters(@proposals)

    @summary = {
      pipeline_value: @proposals.sum(:estimated_value),
      open_proposal_count: @proposals.count,
      active_prospect_count: @prospects.count
    }

    @prospects = @prospects.order(last_activity_date: :desc)
    @proposals = @proposals.order(expected_close_date: :asc)
  end

  private

  def active_prospects
    Prospect.includes(:responsible_consultant)
            .where(status: [ :new_prospect, :contacted, :qualified ])
  end

  def open_proposals
    Proposal.includes(:responsible_consultant)
            .where(status: [ :draft, :sent, :under_review ])
  end

  def apply_prospect_filters(scope)
    scope = scope.where(responsible_consultant_id: params[:consultant_id]) if params[:consultant_id].present?
    scope = scope.where(status: params[:prospect_status]) if params[:prospect_status].present?
    if params[:value_min].present?
      scope = scope.where("estimated_value >= ?", params[:value_min])
    end
    if params[:value_max].present?
      scope = scope.where("estimated_value <= ?", params[:value_max])
    end
    scope
  end

  def apply_proposal_filters(scope)
    scope = scope.where(responsible_consultant_id: params[:consultant_id]) if params[:consultant_id].present?
    scope = scope.where(status: params[:proposal_status]) if params[:proposal_status].present?
    if params[:close_date_from].present?
      scope = scope.where("expected_close_date >= ?", params[:close_date_from])
    end
    if params[:close_date_to].present?
      scope = scope.where("expected_close_date <= ?", params[:close_date_to])
    end
    if params[:value_min].present?
      scope = scope.where("estimated_value >= ?", params[:value_min])
    end
    if params[:value_max].present?
      scope = scope.where("estimated_value <= ?", params[:value_max])
    end
    scope
  end
end
