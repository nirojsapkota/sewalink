class AdminActivityLog < ApplicationRecord
  belongs_to :admin, class_name: 'User'

  def self.record!(admin:, action:, target: nil, details: {})
    create!(
      admin: admin,
      action: action,
      target_type: target&.class&.name,
      target_id: target&.id,
      details: details.to_json
    )
  end
end
