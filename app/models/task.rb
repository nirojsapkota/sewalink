class Task < ApplicationRecord
  belongs_to :user
  belongs_to :category

  has_many :bids, dependent: :destroy
  has_many_attached :photos

  enum status: { draft: 0, open: 1, assigned: 2, completed: 3, cancelled: 4 }

  geocoded_by :location
  after_validation :geocode, if: ->(obj){ obj.location.present? && obj.location_changed? }

  validates :title, presence: true
  validates :description, presence: true
  validates :budget, presence: true, numericality: { greater_than: 0 }
  validates :location, presence: true
  validates :category_id, presence: true
  validates :status, presence: true

  broadcasts_refreshes
end
