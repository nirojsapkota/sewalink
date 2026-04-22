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
    when 'query_tasks'
      search_query = args['search_query']
      
      if current_user.poster?
        tasks = current_user.tasks
        tasks = tasks.where("title ILIKE ? OR description ILIKE ?", "%#{search_query}%", "%#{search_query}%") if search_query.present?
        
        summary = {
          role: "Poster",
          counts: {
            total: tasks.count,
            draft: tasks.draft.count,
            open: tasks.open.count,
            in_progress: tasks.in_progress.count,
            completed: tasks.completed.count,
            disputed: tasks.dispute.count
          },
          recent_tasks: tasks.order(updated_at: :desc).limit(5).map { |t| 
            { id: t.id, title: t.title, status: t.status, budget: t.budget.to_f } 
          }
        }
        render json: { result: "success", data: summary }
      else
        # Tasker Role
        bids = current_user.bids
        active_jobs = current_user.assigned_tasks.in_progress
        
        summary = {
          role: "Tasker",
          counts: {
            total_bids: bids.count,
            pending_bids: bids.pending.count,
            accepted_bids: bids.accepted.count,
            active_jobs: active_jobs.count
          },
          recent_bids: bids.order(created_at: :desc).limit(5).map { |b|
            { task_title: b.task.title, amount: b.amount.to_f, status: b.status }
          },
          active_job_details: active_jobs.limit(5).map { |t|
            { id: t.id, title: t.title, budget: t.budget.to_f }
          }
        }
        render json: { result: "success", data: summary }
      end
    else
      render json: { result: "error", message: "Unknown tool: #{name}" }, status: :not_found
    end
  end
end
