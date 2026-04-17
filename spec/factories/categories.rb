FactoryBot.define do
  factory :category do
    sequence(:name_en) { |n| "Category_en_#{n}_#{SecureRandom.hex(4)}" }
    sequence(:name_ne) { |n| "Category_ne_#{n}_#{SecureRandom.hex(4)}" }
  end
end
