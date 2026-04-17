FactoryBot.define do
  factory :conversation do
    association :bid
    association :task
  end
end
