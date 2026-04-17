class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  def create
    authorize @conversation, :show?
    @message = @conversation.messages.build(message_params)
    @message.sender = current_user

    if @message.save
      # Broadcast masked version to everyone in the conversation
      @message.broadcast_append_to(
        @conversation,
        target: "messages",
        partial: "messages/message",
        locals: { viewer: nil }
      )

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @conversation }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_message", partial: "messages/form", locals: { conversation: @conversation, message: @message }) }
        format.html { render "conversations/show", status: :unprocessable_entity }
      end
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
