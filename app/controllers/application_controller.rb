class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_authenticated_user
  before_action :require_active_role

  helper_method :current_user

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_authenticated_user
    unless current_user
      redirect_to login_path, alert: "Please sign in to continue."
    end
  end

  def require_active_role
    return unless current_user

    if !current_user.active?
      session[:user_id] = nil
      redirect_to login_path, alert: "Your account has been deactivated."
    elsif current_user.pending?
      redirect_to pending_approval_path
    end
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
