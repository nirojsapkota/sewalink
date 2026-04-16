class Bid < ApplicationRecord
  belongs_to :user
  belongs_to :task

  enum status: { pending: 0, accepted: 1, rejected: 2 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :message, presence: true
  validates :status, presence: true

  # Ensure a tasker can only bid once per task
  validates :user_id, uniqueness: { scope: :task_id, message: "You have already submitted a bid for this task." }

  broadcasts_refreshes
end
