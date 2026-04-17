class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User'

  validates :content, presence: true

  def filtered_content
    # Per D-16, lift masking for Poster and Assigned Tasker once assigned.
    return content if conversation.task.assigned?

    ContentFilterService.mask(content)
  end
end
