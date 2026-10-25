module ApplicationCable
  # Only signed-in, active, approved users may open a WebSocket. Without this,
  # anyone holding a signed stream name could keep receiving live broadcasts.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      user_id = request.session[:user_id]
      user = User.find_by(id: user_id) if user_id
      return user if user&.active? && !user.pending?

      reject_unauthorized_connection
    end
  end
end
