# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

categories = [
  { name_en: "Plumbing", name_ne: "प्लम्बिङ" },
  { name_en: "Electrical", name_ne: "इलेक्ट्रिकल" },
  { name_en: "Cleaning", name_ne: "सफाई" },
  { name_en: "Delivery", name_ne: "डेलिभरी" },
  { name_en: "Construction", name_ne: "निर्माण" },
  { name_en: "Carpentry", name_ne: "सिकर्मी" },
  { name_en: "Painting", name_ne: "रङरोगन" },
  { name_en: "Appliance Repair", name_ne: "उपकरण मर्मत" },
  { name_en: "Moving & Packing", name_ne: "सामान सर्ने/प्याकिङ" },
  { name_en: "Gardening & Landscaping", name_ne: "बगैंचा/भूउद्यान" },
  { name_en: "Pest Control", name_ne: "किरा नियन्त्रण" },
  { name_en: "Home Renovation", name_ne: "घर मर्मत/नवीनीकरण" },
  { name_en: "Furniture Assembly", name_ne: "फर्निचर जडान" },
  { name_en: "AC & Refrigeration", name_ne: "एसी तथा रेफ्रिजरेसन" },
  { name_en: "CCTV & Security Installation", name_ne: "सीसीटीभी तथा सुरक्षा जडान" },
  { name_en: "Vehicle Repair", name_ne: "सवारी मर्मत" },
  { name_en: "Computer & IT Support", name_ne: "कम्प्युटर तथा आईटी सहयोग" },
  { name_en: "Beauty & Spa at Home", name_ne: "ब्युटी तथा स्पा (घरमै)" },
  { name_en: "Tutoring & Lessons", name_ne: "ट्युसन तथा कक्षा" },
  { name_en: "Event Help & Catering", name_ne: "कार्यक्रम सहयोग तथा खानपान" },
  { name_en: "Photography & Videography", name_ne: "फोटोग्राफी तथा भिडियोग्राफी" },
  { name_en: "Laundry & Ironing", name_ne: "लुगा धुने तथा इस्त्री" },
  { name_en: "Babysitting & Elderly Care", name_ne: "बच्चा तथा वृद्ध स्याहार" },
  { name_en: "Pet Care", name_ne: "पशुपालन स्याहार" },
  { name_en: "Roofing & Waterproofing", name_ne: "छाना तथा वाटरप्रूफिङ" },
  { name_en: "Welding & Metal Work", name_ne: "वेल्डिङ तथा धातु काम" },
  { name_en: "Masonry", name_ne: "गजुरी/डकर्मी" },
  { name_en: "Interior Design & Decoration", name_ne: "आन्तरिक डिजाइन तथा सजावट" },
  { name_en: "Document & Errand Services", name_ne: "कागजात तथा एरेन्ड सेवा" },
  { name_en: "Other", name_ne: "अन्य" }
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
  email: "nirojsapkota15@gmail.com",
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
