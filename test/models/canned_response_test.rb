require "test_helper"

class CannedResponseTest < ActiveSupport::TestCase
  test "valid canned response" do
    cr = build(:canned_response)
    assert cr.valid?
  end

  test "requires name" do
    cr = build(:canned_response, name: nil)
    assert_not cr.valid?
    assert_includes cr.errors[:name], "can't be blank"
  end

  test "requires content" do
    cr = build(:canned_response, content: nil)
    assert_not cr.valid?
    assert_includes cr.errors[:content], "can't be blank"
  end

  test "key uniqueness" do
    create(:canned_response, key: "test_key")
    duplicate = build(:canned_response, key: "test_key")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end

  test "allows multiple nil keys" do
    create(:canned_response, key: nil)
    another = build(:canned_response, key: nil)
    assert another.valid?
  end

  test "ordered scope sorts by position then name" do
    c = create(:canned_response, name: "C reply", position: 1)
    a = create(:canned_response, name: "A reply", position: 0)
    b = create(:canned_response, name: "B reply", position: 1)

    assert_equal [ a, b, c ], CannedResponse.ordered.to_a
  end

  test "auto_disconnect returns the system disconnect response" do
    cr = create(:canned_response, :auto_disconnect)
    assert_equal cr, CannedResponse.auto_disconnect
  end

  test "auto_disconnect returns nil when not present" do
    assert_nil CannedResponse.auto_disconnect
  end

  test "system? returns true when key is present" do
    cr = build(:canned_response, key: "some_key")
    assert cr.system?
  end

  test "system? returns false when key is nil" do
    cr = build(:canned_response, key: nil)
    assert_not cr.system?
  end
end
