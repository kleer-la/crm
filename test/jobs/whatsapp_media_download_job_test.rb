require "test_helper"

class WhatsappMediaDownloadJobTest < ActiveSupport::TestCase
  setup do
    @message = create(:message, :image)
    @job = WhatsappMediaDownloadJob.new
  end

  test "downloads media and attaches it to the message" do
    @job.define_singleton_method(:fetch_media_info) do |media_id|
      { "url" => "https://lookaside.example/media/#{media_id}", "mime_type" => "image/jpeg" }
    end
    @job.define_singleton_method(:download_media) { |_url| "jpeg-bytes" }

    @job.perform(@message)

    assert @message.file.attached?
    assert_equal "image/jpeg", @message.file.content_type
    assert_equal "image-img_123.jpeg", @message.file.filename.to_s
    assert_equal "jpeg-bytes", @message.file.download
  end

  test "uses document filename when present" do
    message = create(:message, message_type: :document, content: "report.pdf",
                     metadata: { "document" => { "id" => "doc_1", "filename" => "report.pdf" } })
    @job.define_singleton_method(:fetch_media_info) do |_id|
      { "url" => "https://lookaside.example/media/doc_1", "mime_type" => "application/pdf" }
    end
    @job.define_singleton_method(:download_media) { |_url| "pdf-bytes" }

    @job.perform(message)

    assert_equal "report.pdf", message.file.filename.to_s
  end

  test "strips codec params from mime type" do
    message = create(:message, message_type: :audio, content: "[Audio]",
                     metadata: { "audio" => { "id" => "aud_1" } })
    @job.define_singleton_method(:fetch_media_info) do |_id|
      { "url" => "https://lookaside.example/media/aud_1", "mime_type" => "audio/ogg; codecs=opus" }
    end
    @job.define_singleton_method(:download_media) { |_url| "ogg-bytes" }

    @job.perform(message)

    assert_equal "audio/ogg", message.file.content_type
  end

  test "skips when file already attached" do
    @message.file.attach(io: StringIO.new("existing"), filename: "existing.jpg", content_type: "image/jpeg")
    @job.define_singleton_method(:fetch_media_info) { |_id| raise "should not be called" }

    @job.perform(@message)

    assert_equal "existing.jpg", @message.file.filename.to_s
  end

  test "skips when metadata has no media id" do
    message = create(:message, message_type: :image, content: "[Image]", metadata: {})
    @job.define_singleton_method(:fetch_media_info) { |_id| raise "should not be called" }

    @job.perform(message)

    assert_not message.file.attached?
  end

  test "raises when media info has no url" do
    @job.define_singleton_method(:fetch_media_info) { |_id| { "error" => "gone" } }

    assert_raises(RuntimeError) { @job.perform(@message) }
    assert_not @message.file.attached?
  end
end
