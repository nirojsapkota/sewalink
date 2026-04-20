FactoryBot.define do
  factory :user do
    phone { "98" + Faker::Number.number(digits: 8).to_s }
    email { Faker::Internet.email }
    password { "Password123!" }
    active_role { :poster }
    onboarded { true }

    trait :admin do
      admin { true }
    end
  end
end
