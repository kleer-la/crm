class DashboardController < ApplicationController
  def index
    load_personal_data
    load_team_alerts
    load_admin_data if current_user.admin?
  end

  private

  def my_record_ids(model)
    direct = model.where(responsible_consultant_id: current_user.id)
    collab_ids = ConsultantAssignment.where(user_id: current_user.id, assignable_type: model.name).pluck(:assignable_id)
    model.where(id: direct.select(:id)).or(model.where(id: collab_ids))
  end

  def load_personal_data
    # My open tasks (overdue first, then by due_date)
    my_task_ids = Task.where(assigned_to_id: current_user.id).select(:id)
    @my_tasks = Task.where(id: my_task_ids)
                    .where(status: [ :open, :in_progress ])
                    .order(Arel.sql("CASE WHEN due_date < CURRENT_DATE THEN 0 ELSE 1 END, due_date ASC"))
                    .limit(20)

    # My proposals by status
    @my_proposals = my_record_ids(Proposal).open.includes(:linkable).order(expected_close_date: :asc)

    # My active prospects
    @my_prospects = my_record_ids(Prospect)
                      .where(status: [ :new_prospect, :contacted, :qualified ])
                      .includes(:responsible_consultant)
                      .order(last_activity_date: :desc)
                      .limit(10)

    # Recent activity on my records
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
    ).includes(:user, :loggable).order(created_at: :desc).limit(15)

    # Personal metrics
    @my_pipeline_value = my_record_ids(Proposal).open.sum(:estimated_value)
    @proposals_sent_this_month = my_record_ids(Proposal)
                                   .where(status: [ :sent, :under_review, :won, :lost, :cancelled ])
                                   .where("date_sent >= ?", Date.current.beginning_of_month)
                                   .count
    @proposals_won_this_month = my_record_ids(Proposal)
                                  .where(status: :won)
                                  .where("actual_close_date >= ?", Date.current.beginning_of_month)
                                  .count

    # My stale proposals
    @my_stale_proposals = my_record_ids(Proposal).stale.includes(:linkable)
  end

  def load_team_alerts
    @pending_conversions = Proposal.pending_conversion.includes(:linkable, :responsible_consultant)
    @team_stale_proposals = Proposal.stale.includes(:linkable, :responsible_consultant)
  end

  def load_admin_data
    @team_pipeline_value = Proposal.open.sum(:estimated_value)
    @team_proposals_sent = Proposal.where(status: [ :sent, :under_review, :won, :lost, :cancelled ])
                                   .where("date_sent >= ?", Date.current.beginning_of_month)
                                   .count
    @team_proposals_won = Proposal.where(status: :won)
                                  .where("actual_close_date >= ?", Date.current.beginning_of_month)
                                  .count
    @all_overdue_tasks = Task.overdue.includes(:assigned_to, :linkable).order(due_date: :asc)
  end
end
