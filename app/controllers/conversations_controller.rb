class ConversationsController < ApplicationController
  def index
    @conversations = Conversation.recent.includes(:messages)
    @conversations = @conversations.where(platform: params[:platform]) if params[:platform].present?
    @conversations = @conversations.where(status: params[:status]) if params[:status].present?
  end

  def show
    @conversation = Conversation.find(params[:id])
    @messages = @conversation.messages.order(sent_at: :asc)
  end
end
