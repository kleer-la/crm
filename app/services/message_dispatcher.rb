class MessageDispatcher
  Result = Struct.new(:success, :error, keyword_init: true)

  def initialize(provider: nil)
    @provider = provider || default_provider
  end

  def dispatch(message)
    return Result.new(success: true) if message.note?

    @provider.send_message(message)
  end

  private

  def default_provider
    NullProvider.new
  end
end
