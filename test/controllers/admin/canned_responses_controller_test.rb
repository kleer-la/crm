require "test_helper"

class Admin::CannedResponsesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in(@admin)
    @canned_response = create(:canned_response)
  end

  test "index lists canned responses" do
    get admin_canned_responses_path
    assert_response :success
    assert_includes response.body, @canned_response.name
  end

  test "new renders form" do
    get new_admin_canned_response_path
    assert_response :success
  end

  test "create with valid params" do
    assert_difference "CannedResponse.count", 1 do
      post admin_canned_responses_path, params: {
        canned_response: { name: "Greeting", content: "Hello!", position: 1 }
      }
    end
    assert_redirected_to admin_canned_responses_path
  end

  test "create with invalid params renders form" do
    assert_no_difference "CannedResponse.count" do
      post admin_canned_responses_path, params: {
        canned_response: { name: "", content: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edit renders form" do
    get edit_admin_canned_response_path(@canned_response)
    assert_response :success
  end

  test "update with valid params" do
    patch admin_canned_response_path(@canned_response), params: {
      canned_response: { content: "Updated content" }
    }
    assert_redirected_to admin_canned_responses_path
    assert_equal "Updated content", @canned_response.reload.content
  end

  test "destroy removes canned response" do
    assert_difference "CannedResponse.count", -1 do
      delete admin_canned_response_path(@canned_response)
    end
    assert_redirected_to admin_canned_responses_path
  end

  test "non-admin cannot access" do
    sign_in(create(:user))
    get admin_canned_responses_path
    assert_redirected_to root_path
  end
end
