require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "login page renders for unauthenticated user" do
    get login_path
    assert_response :success
  end

  test "login page redirects active user to root" do
    user = create(:user)
    sign_in(user)
    get login_path
    assert_redirected_to root_path
  end

  test "oauth callback creates new user as pending" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "new_uid_123",
      info: { email: "newuser@example.com", name: "New User", image: "http://example.com/avatar.png" }
    )

    assert_difference "User.count", 1 do
      get "/auth/google_oauth2/callback"
    end

    user = User.last
    assert_equal "pending", user.role
    assert_equal "newuser@example.com", user.email
    assert_redirected_to pending_approval_path
  end

  test "oauth callback signs in existing active user" do
    user = create(:user, google_uid: "existing_uid")

    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "existing_uid",
      info: { email: user.email, name: "Updated Name", image: "http://example.com/new.png" }
    )
    get "/auth/google_oauth2/callback"

    assert_redirected_to root_path
    assert_equal "Updated Name", user.reload.name
  end

  test "oauth callback rejects deactivated user with flash message" do
    user = create(:user, :deactivated, google_uid: "deactivated_uid")

    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "deactivated_uid",
      info: { email: user.email, name: user.name, image: nil }
    )
    get "/auth/google_oauth2/callback"

    assert_redirected_to login_path
    assert_match(/deactivated/i, flash[:alert])
  end

  test "reactivated user can log in again" do
    user = create(:user, :deactivated, google_uid: "reactivated_uid")
    user.update!(active: true)

    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "reactivated_uid",
      info: { email: user.email, name: user.name, image: nil }
    )
    get "/auth/google_oauth2/callback"

    assert_redirected_to root_path
    assert_equal user.id, session[:user_id]
  end

  test "oauth callback redirects pending user to pending page" do
    user = create(:user, :pending, google_uid: "pending_uid")

    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "pending_uid",
      info: { email: user.email, name: user.name, image: nil }
    )
    get "/auth/google_oauth2/callback"

    assert_redirected_to pending_approval_path
  end

  test "oauth callback links imported user by email when no google_uid" do
    imported_user = create(:user, name: "Imported name", email: "imported@example.com", google_uid: nil, role: :consultant)

    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "new_google_uid_456",
      info: { email: "imported@example.com", name: "Updated Name", image: "http://example.com/avatar.png" }
    )

    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end

    imported_user.reload
    assert_equal "new_google_uid_456", imported_user.google_uid
    assert_equal "Imported name", imported_user.name
    assert_equal "consultant", imported_user.role
    assert_redirected_to root_path
  end

  test "oauth callback creates new user when no google_uid or email match" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "brand_new_uid",
      info: { email: "brand_new@example.com", name: "Brand New", image: nil }
    )

    assert_difference "User.count", 1 do
      get "/auth/google_oauth2/callback"
    end

    user = User.find_by(email: "brand_new@example.com")
    assert_equal "brand_new_uid", user.google_uid
    assert_equal "pending", user.role
  end

  test "oauth callback still works for existing user with google_uid" do
    user = create(:user, google_uid: "known_uid", email: "known@example.com")

    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "known_uid",
      info: { email: "known@example.com", name: "Known User Updated", image: nil }
    )

    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end

    assert_equal "Known User Updated", user.reload.name
    assert_redirected_to root_path
  end

  test "auth failure redirects to login with alert" do
    get "/auth/failure"
    assert_redirected_to login_path
  end

  test "pending page accessible by pending user" do
    user = create(:user, :pending)
    sign_in(user)
    get pending_approval_path
    assert_response :success
  end

  test "pending page redirects non-pending user to root" do
    user = create(:user)
    sign_in(user)
    get pending_approval_path
    assert_redirected_to root_path
  end

  test "logout clears session" do
    user = create(:user)
    sign_in(user)
    delete logout_path
    assert_redirected_to login_path
  end

  test "unauthenticated user is redirected to login" do
    get root_path
    assert_redirected_to login_path
  end

  test "deactivated user is redirected to login on next request" do
    user = create(:user)
    sign_in(user)
    user.update!(active: false)
    get root_path
    assert_redirected_to login_path
  end

  test "pending user is redirected to pending approval from protected pages" do
    user = create(:user, :pending)
    sign_in(user)
    get prospects_path
    assert_redirected_to pending_approval_path
  end
end
