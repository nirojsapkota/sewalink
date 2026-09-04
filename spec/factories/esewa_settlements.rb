FactoryBot.define do
  factory :esewa_settlement do
    transaction_ref { "ESW#{SecureRandom.hex(4).upcase}" }
    amount_cents { 1000_00 }
    settled_on { Date.current }
    status { "unmatched" }
    association :imported_by, factory: :user
  end
end
