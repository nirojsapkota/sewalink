class Category < ApplicationRecord
  validates :name_en, presence: true, uniqueness: true
  validates :name_ne, presence: true, uniqueness: true
end
