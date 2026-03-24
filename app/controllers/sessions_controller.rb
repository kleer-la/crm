class SessionsController < ApplicationController
  skip_before_action :require_authenticated_user, only: [ :new, :create, :failure ]
  skip_before_action :require_active_role, only: [ :new, :create, :failure, :pending, :destroy ]

  def new
    redirect_to root_path if current_user&.active? && !current_user.pending?
  end

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_by(google_uid: auth.uid)

    if user
      user.update!(name: auth.info.name, avatar_url: auth.info.image)
    elsif (user = User.find_by(email: auth.info.email))
      user.update!(google_uid: auth.uid, name: auth.info.name, avatar_url: auth.info.image)
    else
      user = User.create!(
        google_uid: auth.uid,
        email: auth.info.email,
        name: auth.info.name,
        avatar_url: auth.info.image,
        role: :pending,
        active: true
      )
    end

    if !user.active?
      redirect_to login_path, alert: "Your account has been deactivated. Please contact an administrator."
      return
    end

    session[:user_id] = user.id

    if user.pending?
      redirect_to pending_approval_path
    else
      redirect_to root_path, notice: "Signed in successfully."
    end
  end

  def failure
    redirect_to login_path, alert: "Authentication failed. Please try again."
  end

  def pending
    redirect_to root_path if current_user && !current_user.pending?
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Signed out successfully."
  end
end
