class EsewaSettlement < ApplicationRecord
  belongs_to :imported_by, class_name: "User"

  monetize :amount_cents

  enum status: { unmatched: "unmatched", matched: "matched", mismatched: "mismatched" }

  validates :transaction_ref, presence: true
  validates :settled_on, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
end
