class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  def create
    authorize @conversation, :show?
    @message = @conversation.messages.build(message_params)
    @message.sender = current_user

    if @message.save
      # Broadcast masked version to everyone in the conversation (publicly)
      @message.broadcast_append_to(
        @conversation,
        target: "messages",
        partial: "messages/message",
        locals: { viewer: nil }
      )

      # Securely broadcast unmasked content to authorized participants privately
      # 1. To Sender (always authorized)
      @message.broadcast_update_to(
        current_user,
        target: "#{ActionView::RecordIdentifier.dom_id(@message)}_text",
        html: @message.content
      )

      # 2. To Recipient (only if authorized)
      other_user = @conversation.other_participant(current_user)
      if @message.viewer_aware_content(other_user) == @message.content
        @message.broadcast_update_to(
          other_user,
          target: "#{ActionView::RecordIdentifier.dom_id(@message)}_text",
          html: @message.content
        )
      end

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
