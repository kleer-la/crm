require "test_helper"

class DocumentVersionTest < ActiveSupport::TestCase
  test "valid document version" do
    dv = build(:document_version)
    assert dv.valid?
  end

  test "requires label" do
    dv = build(:document_version, label: nil)
    assert_not dv.valid?
  end

  test "requires url" do
    dv = build(:document_version, url: nil)
    assert_not dv.valid?
  end

  test "validates url format" do
    dv = build(:document_version, url: "not-a-url")
    assert_not dv.valid?
  end

  test "immutable after persisted - cannot update" do
    dv = create(:document_version)
    assert_raises(ActiveRecord::ReadOnlyRecord) { dv.update!(label: "changed") }
  end
end
