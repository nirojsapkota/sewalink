class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User'

  validates :content, presence: true

  def viewer_aware_content(viewer)
    return content if viewer && (viewer.id == sender_id)
    # Server-side broadcasts will have viewer: nil, so they get masked.
    # Client-side JS will unmask for authorized participants.
    filtered_content
  end

  def filtered_content
    ContentFilterService.mask(content)
  end

  private

  def authorized_participant?(viewer)
    # Poster is authorized
    return true if conversation.task.user_id == viewer.id
    # Assigned Tasker is authorized
    return true if conversation.task.assigned? && conversation.task.tasker&.id == viewer.id
    
    false
  end
end
