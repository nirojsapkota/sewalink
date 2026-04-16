class Task < ApplicationRecord
  belongs_to :user
  belongs_to :category

  has_many :bids, dependent: :destroy
  has_one :accepted_bid, -> { accepted }, class_name: 'Bid'
  has_one :tasker, through: :accepted_bid, source: :user
  has_many :payment_transactions, dependent: :destroy
  has_many_attached :photos

  monetize :budget_cents

  enum status: { draft: 0, open: 1, assigned: 2, in_progress: 3, completed: 4, cancelled: 5 }
  enum payment_type: { esewa: 0, cash: 1 }

  geocoded_by :location
  after_validation :geocode, if: ->(obj){ obj.location.present? && obj.location_changed? }

  validates :title, presence: true
  validates :description, presence: true
  validates :budget, presence: true, numericality: { greater_than: 0 }
  validates :location, presence: true
  validates :category_id, presence: true
  validates :status, presence: true
  validate :must_have_payment_for_digital_task, if: -> { esewa? && (in_progress? || completed?) }

  after_commit :release_escrow_if_completed, on: :update

  broadcasts_refreshes

  def paid?
    payment_transactions.completed.exists?
  end

  private

  def release_escrow_if_completed
    return unless saved_change_to_status? && completed? && esewa?

    Payments::LedgerManager.release_from_escrow(self)
  end

  def must_have_payment_for_digital_task
    if !paid?
      errors.add(:status, "cannot be changed to in_progress or completed without a verified payment for eSewa tasks.")
    end
  end
end
