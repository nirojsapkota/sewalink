FactoryBot.define do
  factory :dispute_evidence do
    association :task
    association :user
    description { "Issue with the work quality" }
    
    after(:build) do |evidence|
      evidence.files.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_image.png')),
        filename: 'test_image.png',
        content_type: 'image/png'
      )
    end
  end
end
