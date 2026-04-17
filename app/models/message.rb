class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User'

  validates :content, presence: true

  # Will implement filtered_content method in Task 2
  def filtered_content
    content # Placeholder for now
  end
end
