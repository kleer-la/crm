module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :assign_role, :deactivate, :reactivate ]

    def index
      @pending_users = User.where(role: :pending, active: true).order(:created_at)
      @active_users = User.where(active: true).where.not(role: :pending).order(:name)
      @deactivated_users = User.where(active: false).order(:name)
    end

    def assign_role
      if @user.update(role: params[:role])
        redirect_to admin_users_path, notice: "#{@user.name} has been assigned the #{@user.role} role."
      else
        redirect_to admin_users_path, alert: "Failed to assign role."
      end
    end

    def deactivate
      @user.update!(active: false)
      redirect_to admin_users_path, notice: "#{@user.name} has been deactivated."
    end

    def reactivate
      @user.update!(active: true)
      redirect_to admin_users_path, notice: "#{@user.name} has been reactivated."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
