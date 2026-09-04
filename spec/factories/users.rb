FactoryBot.define do
  factory :user do
    phone { "98" + Faker::Number.number(digits: 8).to_s }
    email { Faker::Internet.email }
    password { "Password123!" }
    active_role { :poster }
    onboarded { true }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }

    trait :admin do
      admin { true }
      after(:create) { |user| user.add_role(:super_admin) }
    end

    trait :super_admin do
      after(:create) { |user| user.add_role(:super_admin) }
    end

    trait :accountant do
      after(:create) { |user| user.add_role(:accountant) }
    end
  end
end
