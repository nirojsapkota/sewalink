class Bid < ApplicationRecord
  belongs_to :user
  belongs_to :task
  has_one :conversation, dependent: :destroy

  enum status: { pending: 0, accepted: 1, rejected: 2 }
  enum payment_method: { esewa: 0, cash: 1 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :message, presence: true
  validates :status, presence: true
  validates :payment_method, presence: true
  validate :user_can_bid, on: :create

  # Ensure a tasker can only bid once per task
  validates :user_id, uniqueness: { scope: :task_id, message: "You have already submitted a bid for this task." }

  broadcasts_refreshes
  after_create_commit :notify_poster
  after_create :create_conversation

  private

  def notify_poster
    broadcast_prepend_to [task.user, :notifications],
                         target: "notifications",
                         partial: "notifications/toast",
                         locals: { 
                           message: "New bid received!", 
                           description: "A tasker has placed a bid of Rs. #{amount} on '#{task.title}'",
                           link: task
                         }
  end

  def user_can_bid
    return if user&.can_bid?

    errors.add(:base, "You cannot place new bids because your account has a high debt. Please settle your dues.")
  end

  def create_conversation
    Conversation.create!(bid: self, task: task)
  end
end
