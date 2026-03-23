class TasksController < ApplicationController
  include Sortable

  before_action :set_task, only: [ :show, :edit, :update, :destroy, :mark_done, :cancel, :reassign ]

  SORT_FIELDS = %i[title status priority due_date assigned_to_id completed_at].freeze

  def index
    @tasks = Task.includes(:linkable, :assigned_to)
    @tasks = apply_filters(@tasks)
    @tasks = apply_sort(@tasks, allowed_fields: SORT_FIELDS, default_field: :due_date, default_dir: :asc)
  end

  def show
  end

  def new
    @task = Task.new(status: :open, priority: :medium)
    @task.linkable_type = params[:linkable_type] if params[:linkable_type].present?
    @task.linkable_id = params[:linkable_id] if params[:linkable_id].present?
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      redirect_to @task, notice: "Task was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      redirect_to @task, notice: "Task was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!
    redirect_to tasks_path, notice: "Task was successfully deleted."
  end

  def mark_done
    if @task.mark_done!
      redirect_to @task, notice: "Task marked as Done."
    else
      redirect_to @task, alert: @task.errors.full_messages.to_sentence
    end
  end

  def cancel
    reason = params[:task][:cancellation_reason]
    if @task.cancel!(reason)
      redirect_to @task, notice: "Task has been cancelled."
    else
      redirect_to @task, alert: @task.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to @task, alert: @task.errors.full_messages.to_sentence
  end

  def reassign
    if @task.update(assigned_to_id: params[:task][:assigned_to_id])
      redirect_to @task, notice: "Task has been reassigned."
    else
      redirect_to @task, alert: @task.errors.full_messages.to_sentence
    end
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(
      :title, :linkable_type, :linkable_id,
      :assigned_to_id, :due_date, :priority, :status,
      :cancellation_reason, :notes
    )
  end

  def apply_filters(scope)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(priority: params[:priority]) if params[:priority].present?
    scope = scope.where(assigned_to_id: params[:consultant_id]) if params[:consultant_id].present?
    scope = scope.where(linkable_type: params[:linkable_type]) if params[:linkable_type].present?
    scope = scope.where("title ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    if params[:overdue] == "1"
      scope = scope.overdue
    end
    scope
  end
end
