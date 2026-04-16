FactoryBot.define do
  factory :payout_request do
    user { nil }
    amount_cents { 1 }
    status { "MyString" }
    payment_details { "MyText" }
    rejection_reason { "MyText" }
  end
end
