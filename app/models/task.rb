class Task < ApplicationRecord
  belongs_to :user
  belongs_to :category

  has_many :bids, dependent: :destroy
  has_one :accepted_bid, -> { accepted }, class_name: 'Bid'
  has_one :tasker, through: :accepted_bid, source: :user
  has_many :payment_transactions, dependent: :destroy
  has_many_attached :photos

  include AASM

  monetize :budget_cents

  enum status: { draft: 0, open: 1, assigned: 2, in_progress: 3, pending_payment: 4, payment_completed: 5, completed: 6, dispute: 7, cancelled: 8 }
  enum payment_type: { esewa: 0, cash: 1 }

  aasm column: :status, enum: true do
    state :draft, initial: true
    state :open
    state :assigned
    state :in_progress
    state :pending_payment
    state :payment_completed
    state :completed
    state :dispute
    state :cancelled

    event :toggle_draft do
      transitions from: :draft, to: :open
      transitions from: :open, to: :draft
    end

    event :assign do
      transitions from: :open, to: :assigned
    end

    event :start_work do
      transitions from: :assigned, to: :in_progress
    end

    event :request_payment do
      transitions from: :in_progress, to: :pending_payment
    end

    event :release_payment do
      transitions from: :pending_payment, to: :payment_completed, success: :complete!
    end

    event :complete do
      transitions from: [:in_progress, :payment_completed], to: :completed
    end

    event :raise_dispute do
      transitions from: [:open, :assigned, :in_progress, :pending_payment, :payment_completed], to: :dispute
    end

    event :cancel do
      transitions from: [:draft, :open, :assigned, :in_progress], to: :cancelled
    end
  end

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
    return unless saved_change_to_status? && completed?

    if esewa?
      Payments::LedgerManager.release_from_escrow(self)
    elsif cash?
      Payments::LedgerManager.record_cash_commission(self)
    end
  end

  def must_have_payment_for_digital_task
    if !paid?
      errors.add(:status, "cannot be changed to in_progress or completed without a verified payment for eSewa tasks.")
    end
  end
end
