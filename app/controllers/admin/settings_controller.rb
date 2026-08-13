module Admin
  class SettingsController < BaseController
    def edit
    end

    def update
      Setting.set("ig_welcome_enabled", params[:ig_welcome_enabled] == "1" ? "true" : "false")
      redirect_to edit_admin_settings_path, notice: "Settings saved."
    end
  end
end
