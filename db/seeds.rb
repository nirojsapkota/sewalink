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

# --- Demo users: super_admin, poster, tasker ---
default_password = ENV.fetch("SEED_USER_PASSWORD", "Password123!")

super_admin = User.find_or_initialize_by(phone: "9800000001")
super_admin.assign_attributes(
  first_name: "Super",
  last_name: "Admin",
  admin: true,
  onboarded: true,
  password: default_password,
  password_confirmation: default_password
)
super_admin.save!(validate: false)
super_admin.add_role(:super_admin) unless super_admin.has_role?(:super_admin)

poster = User.find_or_initialize_by(phone: "9800000002")
poster.assign_attributes(
  first_name: "Demo",
  last_name: "Poster",
  active_role: :poster,
  onboarded: true,
  password: default_password,
  password_confirmation: default_password
)
poster.save!(validate: false)

tasker = User.find_or_initialize_by(phone: "9800000003")
tasker.assign_attributes(
  first_name: "Demo",
  last_name: "Tasker",
  active_role: :tasker,
  onboarded: true,
  password: default_password,
  password_confirmation: default_password
)
tasker.save!(validate: false)

puts "Seeded users: super_admin (#{super_admin.phone}), poster (#{poster.phone}), tasker (#{tasker.phone})"
puts "Default password for seeded users: #{default_password}"
