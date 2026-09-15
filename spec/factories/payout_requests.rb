FactoryBot.define do
  factory :payout_request do
    user { nil }
    amount_cents { 1000_00 }
    status { "pending" }
    payment_details { "eSewa ID: 9800000000" }
    rejection_reason { nil }
  end
end
