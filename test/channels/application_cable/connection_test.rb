require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "connects an active user from the session cookie" do
    user = create(:user)
    connect session: { user_id: user.id }

    assert_equal user, connection.current_user
  end

  test "rejects a connection without a session" do
    assert_reject_connection { connect }
  end

  test "rejects a deactivated user" do
    user = create(:user, active: false)
    assert_reject_connection { connect session: { user_id: user.id } }
  end

  test "rejects a pending user" do
    user = create(:user, role: :pending)
    assert_reject_connection { connect session: { user_id: user.id } }
  end
end
