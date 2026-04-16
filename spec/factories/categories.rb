FactoryBot.define do
  factory :category do
    sequence(:name_en) { |n| "Category #{n}" }
    sequence(:name_ne) { |n| "Nepali Name #{n}" }
  end
end
