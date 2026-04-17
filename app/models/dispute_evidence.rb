class DisputeEvidence < ApplicationRecord
  belongs_to :task
  belongs_to :user

  has_many_attached :files

  validates :description, presence: true
end
