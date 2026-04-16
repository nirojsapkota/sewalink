FactoryBot.define do
  factory :task do
    association :user
    association :category
    title { Faker::Job.title }
    description { Faker::Lorem.paragraph }
    budget { 1000.0 }
    location { "Kathmandu, Nepal" }
    latitude { 27.7172 }
    longitude { 85.3240 }
    status { :open }
  end
end
