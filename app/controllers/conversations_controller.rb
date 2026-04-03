class ConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :older_messages, :assign, :link, :close, :reopen]

  def index
    @conversations = Conversation.recent.includes(:messages, :read_states)
    # Default to open conversations unless explicitly set
    status_filter = params[:status] || "open"
    @conversations = @conversations.where(status: status_filter) unless status_filter == "all"
    @conversations = @conversations.where(platform: params[:platform]) if params[:platform].present?
    @conversations = @conversations.search_by_contact(params[:q]) if params[:q].present?
  end

  def show
    @messages = @conversation.messages.order(sent_at: :desc).limit(50).reverse
    @has_older = @conversation.messages.count > 50
    @conversation.mark_as_read!(current_user)
  end

  def older_messages
    before = Time.zone.parse(params[:before])
    @messages = @conversation.messages.where("sent_at < ?", before).order(sent_at: :desc).limit(50).reverse
    @has_older = @messages.any? && @conversation.messages.where("sent_at < ?", @messages.first.sent_at).exists?

    render partial: "conversations/older_messages", locals: {
      messages: @messages, conversation: @conversation, has_older: @has_older
    }
  end

  def assign
    @conversation.update!(assigned_user_id: params[:assigned_user_id])
    redirect_to @conversation, notice: "Conversation assigned."
  end

  def link
    @conversation.update!(linkable_type: params[:linkable_type], linkable_id: params[:linkable_id])
    redirect_to @conversation, notice: "Conversation linked."
  end

  def close
    @conversation.closed!
    redirect_to @conversation, notice: "Conversation closed."
  end

  def reopen
    @conversation.open!
    redirect_to @conversation, notice: "Conversation reopened."
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end
end
