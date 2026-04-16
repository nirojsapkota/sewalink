class PaymentTransaction < ApplicationRecord
  include AASM

  belongs_to :task

  monetize :amount_cents

  validates :transaction_uuid, presence: true, uniqueness: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }

  aasm column: :status do
    state :pending, initial: true
    state :completed
    state :failed

    event :complete do
      transitions from: :pending, to: :completed
    end

    event :fail do
      transitions from: :pending, to: :failed
    end
  end

  after_commit :deposit_to_escrow_if_completed, on: :update

  before_validation :generate_transaction_uuid, on: :create

  private

  def deposit_to_escrow_if_completed
    return unless saved_change_to_status? && completed?

    Payments::LedgerManager.deposit_to_escrow(task)
  end

  def generate_transaction_uuid
    self.transaction_uuid ||= SecureRandom.uuid
  end
end
