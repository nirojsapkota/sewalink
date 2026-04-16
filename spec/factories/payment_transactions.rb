FactoryBot.define do
  factory :payment_transaction do
    association :task
    amount_cents { 100000 }
    transaction_uuid { SecureRandom.uuid }
    status { "pending" }
  end
end
