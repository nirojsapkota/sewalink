FactoryBot.define do
  factory :bid do
    association :user
    association :task
    amount { 1000.0 }
    message { Faker::Lorem.sentence }
    status { :pending }
    payment_method { :esewa }

    trait :accepted do
      status { :accepted }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end
