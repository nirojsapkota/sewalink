# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

categories = [
  { name_en: "Plumbing", name_ne: "प्लम्बिङ" },
  { name_en: "Electrical", name_ne: "इलेक्ट्रिकल" },
  { name_en: "Cleaning", name_ne: "सफाई" },
  { name_en: "Delivery", name_ne: "डेलिभरी" },
  { name_en: "Construction", name_ne: "निर्माण" }
]

categories.each do |cat|
  Category.find_or_create_by!(name_en: cat[:name_en]) do |category|
    category.name_ne = cat[:name_ne]
  end
end

puts "Seeded #{Category.count} categories."
