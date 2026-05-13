class EnsureIntakeUserExists < ActiveRecord::Migration[8.1]
  def up
    User.find_or_create_by!(email: "info@kleer.la") do |user|
      user.name = "Intake"
      user.role = :consultant
      user.active = true
    end
  end

  def down
    User.find_by(email: "info@kleer.la")&.destroy!
  end
end
