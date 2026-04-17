class Review < ApplicationRecord
  belongs_to :task
  belongs_to :reviewer, class_name: 'User'
  belongs_to :reviewee, class_name: 'User'

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, presence: true, if: :is_public?

  scope :visible, -> {
    joins(:task).where(
      'reviews.id IN (
        SELECT r1.id FROM reviews r1
        JOIN tasks t1 ON r1.task_id = t1.id
        WHERE t1.completed_at < ?
      ) OR EXISTS (
        SELECT 1 FROM reviews r2
        WHERE r2.task_id = reviews.task_id
        AND r2.id != reviews.id
      )', 14.days.ago
    )
  }

  def visible?
    task_completed_window_closed? || counterpart_review.present?
  end

  def counterpart_review
    task.reviews.where.not(id: id).first
  end

  private

  def task_completed_window_closed?
    task.completed_at && task.completed_at < 14.days.ago
  end
end
