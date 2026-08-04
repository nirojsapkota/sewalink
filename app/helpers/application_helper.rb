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

  def nav_link_class(path)
    base_classes = "text-sm transition-all duration-200 hover:-translate-y-0.5 active:translate-y-0"
    if current_page?(path)
      "#{base_classes} font-semibold text-[#7C3AED]"
    else
      "#{base_classes} font-medium text-[#4C1D95]/70 hover:text-[#7C3AED]"
    end
  end

  def admin_nav_link_class(path)
    base_classes = "transition-all duration-200 hover:-translate-y-0.5 active:translate-y-0"
    if current_page?(path)
      "#{base_classes} text-white font-bold"
    else
      "#{base_classes} text-gray-300 hover:text-white"
    end
  end

  def language_link_class(path)
    base_classes = "text-xs transition-all duration-200 hover:-translate-y-0.5 active:translate-y-0"
    if current_page?(path)
      "#{base_classes} font-bold text-[#7C3AED]"
    else
      "#{base_classes} font-bold text-[#4C1D95]/40 hover:text-[#7C3AED]"
    end
  end

  def user_dashboard_path
    return root_path unless user_signed_in?

    if current_user.poster?
      poster_dashboard_path
    else
      tasker_dashboard_path
    end
  end
end
