class Gemini::ToolsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:execute]

  def execute
    name = params[:name]
    args = params[:args]
    call_id = params[:call_id]

    case name
    when 'create_task_draft'
      Rails.logger.info "[GeminiTools] Executing create_task_draft with args: #{args.inspect}"
      task = current_user.tasks.draft.last || current_user.tasks.new(status: :draft)
      
      task.title = args['title'] if args['title'].present?
      task.description = args['description'] if args['description'].present?
      
      if args['budget'].present?
        # Clean the budget string if it contains currency symbols or commas
        clean_budget = args['budget'].to_s.gsub(/[^\d.]/, '')
        task.budget = clean_budget if clean_budget.present?
      end
      
      task.location = args['location'] if args['location'].present?
      task.category ||= Category.first

      if task.save
        Rails.logger.info "[GeminiTools] Task #{task.id} saved successfully"
        Turbo::StreamsChannel.broadcast_replace_to(
          current_user, :live_chat,
          target: "ai_task_preview",
          partial: "live_chats/task_preview",
          locals: { task: task }
        )
        render json: { result: "success", task_id: task.id }
      else
        Rails.logger.error "[GeminiTools] Failed to save task: #{task.errors.full_messages.join(", ")}"
        render json: { result: "error", message: task.errors.full_messages.join(", ") }
      end
    when 'publish_task'
      task = current_user.tasks.draft.last
      if task.nil?
        render json: { result: "error", message: "No draft task found to publish." }
      else
        task.status = :open
        if task.save
          Rails.logger.info "[GeminiTools] Task #{task.id} published successfully"
          Turbo::StreamsChannel.broadcast_replace_to(
            current_user, :live_chat,
            target: "ai_task_preview",
            partial: "live_chats/task_preview",
            locals: { task: task }
          )
          render json: { result: "success", message: "Task published successfully", task_id: task.id }
        else
          Rails.logger.error "[GeminiTools] Failed to publish task: #{task.errors.full_messages.join(", ")}"
          render json: { result: "error", message: "Cannot publish: #{task.errors.full_messages.join(", ")}" }
        end
      end
    else
      render json: { result: "error", message: "Unknown tool: #{name}" }, status: :not_found
    end
  end
end
