require "test_helper"

class MessageDispatcherTest < ActiveSupport::TestCase
  test "dispatches text message to provider" do
    message = create(:message, :outbound, message_type: :text)
    result = MessageDispatcher.new.dispatch(message)
    assert result.success
  end

  test "skips dispatch for note messages" do
    message = create(:message, direction: :outbound, message_type: :note, content: "Internal note")
    call_count = 0
    provider = Object.new
    provider.define_singleton_method(:send_message) { |_| call_count += 1 }

    result = MessageDispatcher.new(provider: provider).dispatch(message)
    assert result.success
    assert_equal 0, call_count
  end

  test "uses custom provider when given" do
    message = create(:message, :outbound, message_type: :text)
    called_with = nil
    provider = Object.new
    provider.define_singleton_method(:send_message) do |msg|
      called_with = msg
      MessageDispatcher::Result.new(success: true)
    end

    result = MessageDispatcher.new(provider: provider).dispatch(message)
    assert result.success
    assert_equal message, called_with
  end
end
