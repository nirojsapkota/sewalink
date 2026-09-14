class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  def create
    authorize @conversation, :show?
    @message = @conversation.messages.build(message_params)
    @message.sender = current_user

    if @message.save
      # Broadcast to the other participant only, rendering exactly the view
      # they're authorized to see. The sender already gets their own message
      # via the direct turbo_stream response below, so there's no need for a
      # separate masked broadcast to be corrected afterwards - avoids a race
      # where the sender's own bubble would flash masked before flipping to
      # unmasked content.
      other_user = @conversation.other_participant(current_user)
      @message.broadcast_append_to(
        other_user,
        target: "messages",
        partial: "messages/message",
        locals: { viewer: other_user }
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
