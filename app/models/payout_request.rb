class PayoutRequest < ApplicationRecord
  include AASM

  belongs_to :user

  monetize :amount_cents

  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 500_00 } # NPR 500
  validate :sufficient_balance, on: :create

  aasm column: :status, use_transactions: false do
    state :pending, initial: true
    state :processed
    state :rejected

    event :process do
      transitions from: :pending, to: :processed, after: :deduct_from_ledger
    end

    event :reject do
      transitions from: :pending, to: :rejected
    end
  end

  private

  def sufficient_balance
    return if user.blank? || amount.blank?

    if user.balance < amount
      errors.add(:amount, "exceeds your current balance of #{user.balance.format}")
    end
  end

  def deduct_from_ledger
    DoubleEntry.transfer(
      amount,
      from: DoubleEntry.account(:tasker_balance, scope: user),
      to: DoubleEntry.account(:user_external),
      code: :payout
    )
  end
end
