class Task < ApplicationRecord
  belongs_to :user
  belongs_to :category

  has_many :bids, dependent: :destroy
  has_one :accepted_bid, -> { accepted }, class_name: 'Bid'
  has_one :tasker, through: :accepted_bid, source: :user
  has_many :payment_transactions, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :dispute_evidences, dependent: :destroy
  has_many_attached :photos
  has_one_attached :completion_photo

  include AASM

  monetize :budget_cents

  attr_accessor :current_lat, :current_lng

  enum status: { draft: 0, open: 1, assigned: 2, in_progress: 3, pending_payment: 4, payment_completed: 5, completed: 6, dispute: 7, cancelled: 8 }
  enum payment_type: { esewa: 0, cash: 1 }

  aasm column: :status, enum: true do
    state :draft, initial: true
    state :open
    state :assigned
    state :in_progress
    state :pending_payment
    state :payment_completed
    state :completed
    state :dispute
    state :cancelled

    event :toggle_draft do
      transitions from: :draft, to: :open
      transitions from: :open, to: :draft
    end

    event :assign do
      transitions from: :open, to: :assigned
    end

    event :start_work do
      transitions from: :assigned, to: :in_progress, guard: :within_geofence?
    end

    event :request_payment do
      transitions from: :in_progress, to: :pending_payment
    end

    event :release_payment do
      transitions from: :pending_payment, to: :completed
    end

    event :complete do
      transitions from: :in_progress, to: :completed,
                  guard: [:within_geofence?, :completion_photo_attached?]
    end

    event :raise_dispute do
      transitions from: [:open, :assigned, :in_progress, :pending_payment, :payment_completed], to: :dispute
    end

    event :cancel do
      transitions from: [:draft, :open, :assigned, :in_progress], to: :cancelled
    end
  end

  geocoded_by :location
  after_validation :geocode, if: ->(obj){ obj.location.present? && obj.location_changed? }

  validates :title, presence: true
  validates :description, presence: true
  validates :budget, presence: true, numericality: { greater_than: 0 }
  validates :location, presence: true
  validates :category_id, presence: true
  validates :status, presence: true
  validate :must_have_payment_for_digital_task, if: -> { esewa? && (in_progress? || completed?) }

  after_commit :release_escrow_if_completed, on: :update
  after_update_commit :set_completed_at, if: :completed_and_saved_status_changed?

  broadcasts_refreshes
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?

  def paid?
    payment_transactions.completed.exists?
  end

  def within_geofence?
    return true unless on_site # D-01: Geofencing logic applies strictly to tasks where on_site is true.
    return false if current_lat.blank? || current_lng.blank?

    distance = distance_from([current_lat, current_lng], :km)
    # D-04: Default radius is set to 200m (0.2km)
    distance.present? && distance <= 0.2
  end

  def completion_photo_attached?
    completion_photo.attached?
  end

  def check_in!
    start_work!
  rescue AASM::InvalidTransition => e
    Rails.logger.warn "Task #{id} could not transition to in_progress: #{e.message}"
    false # Indicate failure to transition
  end

  private

  def broadcast_status_change
    broadcast_replace_to self, target: "task_#{id}", partial: 'tasks/task', locals: { task: self }
    notify_status_change
  end

  def notify_status_change
    # Notify the "other" user
    recipient = (status_changed_by_poster? ? tasker : user)
    return unless recipient

    broadcast_prepend_to [recipient, :notifications],
                         target: "notifications",
                         partial: "notifications/toast",
                         locals: { 
                           message: "Task Status Updated", 
                           description: "The task '#{title}' is now #{status.humanize}.",
                           link: self
                         }
  end

  def status_changed_by_poster?
    # Logic to determine who likely changed the status based on the new status
    [:draft, :open, :assigned, :payment_completed, :completed].include?(status.to_sym)
  end

  def release_escrow_if_completed
    return unless saved_change_to_status? && completed?

    if esewa?
      Payments::LedgerManager.release_from_escrow(self)
    elsif cash?
      Payments::LedgerManager.record_cash_commission(self)
    end
  end

  def must_have_payment_for_digital_task
    if !paid?
      errors.add(:status, "cannot be changed to in_progress or completed without a verified payment for eSewa tasks.")
    end
  end

  def set_completed_at
    update_column(:completed_at, Time.current)
    CloseReviewWindowJob.set(wait: 14.days).perform_later(id)
  end

  def completed_and_saved_status_changed?
    saved_change_to_status? && completed?
  end
end
