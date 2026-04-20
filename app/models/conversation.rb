class Conversation < ApplicationRecord
  belongs_to :bid
  belongs_to :task
  has_many :messages, dependent: :destroy

  validates :bid_id, uniqueness: { scope: :task_id, message: "A conversation for this bid and task already exists." }

  # Per D-15: Non-assigned bidder chats are archived/hidden
  scope :active, -> { where(archived: false) }

  def archive!
    update(archived: true)
  end

  def other_participant(user)
    user == task.user ? bid.user : task.user
  end
end
