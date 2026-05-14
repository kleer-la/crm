require "test_helper"

module Conversations
end

class Conversations::MediaContentTest < ActionView::TestCase
  test "renders image with url" do
    message = build(:message, message_type: :image, content: "A photo",
                    metadata: { "image" => { "url" => "https://example.com/photo.jpg" } })
    render partial: "conversations/media_content", locals: { message: message }
    assert_includes rendered, "https://example.com/photo.jpg"
    assert_includes rendered, "A photo"
  end

  test "renders audio player" do
    message = build(:message, message_type: :audio, content: "[Audio]",
                    metadata: { "audio" => { "url" => "https://example.com/audio.mp3" } })
    render partial: "conversations/media_content", locals: { message: message }
    assert_includes rendered, "audio"
    assert_includes rendered, "https://example.com/audio.mp3"
  end

  test "renders audio fallback when no url" do
    message = build(:message, message_type: :audio, content: "[Audio]", metadata: {})
    render partial: "conversations/media_content", locals: { message: message }
    assert_includes rendered, "Audio message"
  end

  test "renders document download link" do
    message = build(:message, message_type: :document, content: "report.pdf",
                    metadata: { "document" => { "url" => "https://example.com/report.pdf",
                                                 "filename" => "report.pdf" } })
    render partial: "conversations/media_content", locals: { message: message }
    assert_includes rendered, "https://example.com/report.pdf"
    assert_includes rendered, "report.pdf"
  end

  test "renders document without url" do
    message = build(:message, message_type: :document, content: "report.pdf",
                    metadata: {})
    render partial: "conversations/media_content", locals: { message: message }
    assert_includes rendered, "Document"
  end

  test "renders location with coordinates" do
    message = build(:message, message_type: :location, content: "[Location]",
                    metadata: { "location" => { "latitude" => -34.6037, "longitude" => -58.3816,
                                                 "name" => "Buenos Aires" } })
    render partial: "conversations/media_content", locals: { message: message }
    assert_includes rendered, "Buenos Aires"
    assert_includes rendered, "-34.6037"
    assert_includes rendered, "-58.3816"
  end

  test "renders sticker" do
    message = build(:message, message_type: :sticker, content: "[Sticker]", metadata: {})
    render partial: "conversations/media_content", locals: { message: message }
    assert_includes rendered, "Sticker"
  end
end
