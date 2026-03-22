class TouchpointsController < ApplicationController
  def create
    @loggable = find_loggable

    if @loggable.nil?
      redirect_back fallback_location: root_path, alert: "Record not found."
      return
    end

    @loggable.log_touchpoint(
      touchpoint_type: params[:touchpoint_type],
      content: params[:content],
      user: current_user
    )

    redirect_back fallback_location: root_path, notice: "Touchpoint logged successfully."
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: root_path, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def find_loggable
    case params[:loggable_type]
    when "Prospect"
      Prospect.find_by(id: params[:loggable_id])
    when "Customer"
      Customer.find_by(id: params[:loggable_id])
    when "Proposal"
      Proposal.find_by(id: params[:loggable_id])
    end
  end
end
