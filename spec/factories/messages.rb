FactoryBot.define do
  factory :message do
    association :conversation
    association :sender, factory: :user
    content { "This is a test message." }
  end
end
