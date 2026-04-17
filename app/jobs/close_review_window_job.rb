class CloseReviewWindowJob < ApplicationJob
  queue_as :default

  def perform(task_id)
    task = Task.find_by(id: task_id)
    return unless task

    Rails.logger.info "Review window check for Task ##{task.id}: '#{task.title}'"
    # The `visible?` logic on the Review model is now based on `task.completed_at`.
    # This job currently serves as a placeholder for any future logic
    # that might need to be triggered after 14 days, such as sending notifications
    # or explicitly setting a visibility flag if the logic were to change.
    # For now, no active change is needed as visibility is dynamic.
  end
end
