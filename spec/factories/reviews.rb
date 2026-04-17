FactoryBot.define do
  factory :review do
    association :task
    association :reviewer, factory: :user
    association :reviewee, factory: :user
    rating { 4 }
    comment { "Great work!" }
    is_public { true }
    private_note { "Tasker was very professional." }
  end
end
