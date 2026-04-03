class MessagesController < ApplicationController
  def create
    @conversation = Conversation.find(params[:conversation_id])
    @message = @conversation.messages.build(message_params)
    @message.direction = :outbound
    @message.sent_at = Time.current

    if @message.save
      MessageDispatcher.new.dispatch(@message) unless @message.note?
      head :ok
    else
      render turbo_stream: turbo_stream.replace(
        "reply_composer",
        partial: "conversations/reply_composer",
        locals: { conversation: @conversation, message: @message }
      ), status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :message_type)
  end
end
