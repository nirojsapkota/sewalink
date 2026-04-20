module ApplicationHelper
  def status_badge_class(status)
    case status.to_sym
    when :draft
      'bg-gray-100 text-gray-800'
    when :open
      'bg-blue-100 text-blue-800'
    when :assigned
      'bg-indigo-100 text-indigo-800'
    when :in_progress
      'bg-yellow-100 text-yellow-800'
    when :pending_payment
      'bg-orange-100 text-orange-800'
    when :payment_completed
      'bg-green-100 text-green-800'
    when :completed
      'bg-green-100 text-green-800'
    when :dispute
      'bg-red-100 text-red-800'
    when :cancelled
      'bg-gray-100 text-gray-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end
end
