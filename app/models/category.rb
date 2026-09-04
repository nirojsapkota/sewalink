class Category < ApplicationRecord
  validates :name_en, presence: true, uniqueness: true
  validates :name_ne, presence: true, uniqueness: true

  default_scope { order(:position, :id) }
  scope :active, -> { where(active: true) }

  before_create :set_default_position

  def set_default_position
    self.position = (Category.unscoped.maximum(:position) || 0) + 1 if position.to_i.zero?
  end

  def destroyable?
    !Task.exists?(category_id: id)
  end
end
