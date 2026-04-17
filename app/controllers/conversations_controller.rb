class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show]

  def show
    authorize @conversation
    @messages = @conversation.messages.includes(:sender).order(created_at: :asc)
    @new_message = @conversation.messages.build
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end
end
