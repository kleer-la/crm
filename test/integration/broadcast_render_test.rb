require "test_helper"

class BroadcastRenderTest < ActiveSupport::TestCase
  # Turbo broadcasts render outside a request; the renderer must not fall back
  # to its example.org default host or attachment URLs break in live-appended bubbles.
  test "message partial rendered outside a request uses the real host" do
    message = create(:message, :image)
    message.file.attach(io: StringIO.new("jpeg-bytes"), filename: "photo.jpg", content_type: "image/jpeg")

    html = ApplicationController.render(partial: "conversations/message", locals: { message: message })

    assert_includes html, "photo.jpg"
    assert_not_includes html, "example.org"
  end
end
