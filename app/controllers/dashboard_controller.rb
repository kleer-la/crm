class DashboardController < ApplicationController
  def index
    load_kpi_data
  end

  def team_panel
    @pending_conversions = Proposal.pending_conversion.includes(:linkable, :responsible_consultant)
    @team_stale_proposals = Proposal.stale.includes(:linkable, :responsible_consultant)
    @team_overdue_tasks = Task.overdue.preload(:linkable).includes(:assigned_to).order(due_date: :asc)
    @team_open_proposals = Proposal.open.preload(:linkable).includes(:responsible_consultant).order(expected_close_date: :asc)
    @team_activity = ActivityLog.preload(:loggable).includes(:user).order(occurred_at: :desc).limit(20)
    render layout: false
  end

  def mine_panel
    @my_pending_conversions = my_record_ids(Proposal).pending_conversion.includes(:linkable, :responsible_consultant)
    @my_stale_proposals = my_record_ids(Proposal).stale.preload(:linkable)
    @my_tasks = Task.where(assigned_to_id: current_user.id)
                    .where(status: [ :open, :in_progress ])
                    .order(Arel.sql("CASE WHEN due_date < CURRENT_DATE THEN 0 ELSE 1 END, due_date ASC"))
                    .limit(20)
    @my_proposals = my_record_ids(Proposal).open.preload(:linkable).order(expected_close_date: :asc)
    @my_prospects = my_record_ids(Prospect)
                      .where(status: [ :new_prospect, :contacted, :qualified ])
                      .includes(:responsible_consultant)
                      .order(last_activity_date: :desc)
                      .limit(10)
    my_proposal_ids = my_record_ids(Proposal).pluck(:id)
    my_prospect_ids = my_record_ids(Prospect).pluck(:id)
    my_customer_ids = my_record_ids(Customer).pluck(:id)
    @recent_activity = ActivityLog.where(
      "(loggable_type = 'Proposal' AND loggable_id IN (?)) OR " \
      "(loggable_type = 'Prospect' AND loggable_id IN (?)) OR " \
      "(loggable_type = 'Customer' AND loggable_id IN (?))",
      my_proposal_ids.presence || [ 0 ],
      my_prospect_ids.presence || [ 0 ],
      my_customer_ids.presence || [ 0 ]
    ).preload(:loggable).includes(:user).order(occurred_at: :desc).limit(15)
    render layout: false
  end

  private

  def load_kpi_data
    @team_pipeline_value = Proposal.open.sum(:estimated_value)
    @team_proposals_sent = Proposal.where(status: [ :sent, :under_review, :won, :lost, :cancelled ])
                                   .where("date_sent >= ?", Date.current.beginning_of_month)
                                   .count
    @team_proposals_won = Proposal.where(status: :won)
                                  .where("actual_close_date >= ?", Date.current.beginning_of_month)
                                  .count
  end

  def my_record_ids(model)
    direct = model.where(responsible_consultant_id: current_user.id)
    collab_ids = ConsultantAssignment.where(user_id: current_user.id, assignable_type: model.name).pluck(:assignable_id)
    model.where(id: direct.select(:id)).or(model.where(id: collab_ids))
  end
end
