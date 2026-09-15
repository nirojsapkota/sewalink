module ApplicationHelper
  def status_badge_class(status)
    case status.to_sym
    when :draft, :cancelled
      'bg-slate-100 text-slate-700'
    when :open, :assigned
      'bg-indigo-50 text-indigo-700'
    when :in_progress, :pending_payment
      'bg-amber-50 text-amber-700'
    when :payment_completed, :completed
      'bg-green-50 text-green-700'
    when :dispute
      'bg-red-50 text-red-700'
    else
      'bg-slate-100 text-slate-700'
    end
  end

  def nav_link_class(path)
    base_classes = "text-sm font-medium transition-colors duration-150"
    if current_page?(path)
      "#{base_classes} text-indigo-600 font-semibold"
    else
      "#{base_classes} text-slate-600 hover:text-slate-900"
    end
  end

  def admin_nav_link_class(path)
    base_classes = "transition-colors duration-150"
    if current_page?(path)
      "#{base_classes} text-white font-semibold"
    else
      "#{base_classes} text-slate-300 hover:text-white"
    end
  end

  def language_link_class(path)
    base_classes = "text-xs font-semibold transition-colors duration-150"
    if current_page?(path)
      "#{base_classes} text-indigo-600"
    else
      "#{base_classes} text-slate-400 hover:text-indigo-600"
    end
  end

  def button_class(variant = :primary)
    base = "px-5 py-2.5 rounded-lg text-sm font-semibold transition-colors duration-150 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-600 focus-visible:ring-offset-2 inline-flex items-center justify-center"
    case variant.to_sym
    when :primary
      "#{base} bg-indigo-600 text-white hover:bg-indigo-700"
    when :secondary
      "#{base} bg-white text-slate-700 border border-slate-300 hover:bg-slate-50"
    when :destructive
      "#{base} bg-red-600 text-white hover:bg-red-700"
    when :ghost
      "text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors duration-150 cursor-pointer"
    else
      "#{base} bg-indigo-600 text-white hover:bg-indigo-700"
    end
  end

  def card_class(interactive: false)
    base = "bg-white border border-slate-200 rounded-xl p-4 md:p-6 shadow-sm"
    interactive ? "#{base} hover:border-slate-300 hover:shadow-md transition-shadow duration-150" : base
  end

  def input_class
    "border border-slate-300 rounded-lg px-4 py-2.5 text-base text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:border-indigo-600 transition-colors duration-150 w-full"
  end

  def user_dashboard_path
    return root_path unless user_signed_in?

    if current_user.poster?
      poster_dashboard_path
    else
      tasker_dashboard_path
    end
  end

  # Renders a small circular avatar image if the user has one attached,
  # otherwise falls back to an initials badge. Used anywhere we show a
  # compact identity marker (chat bubbles, conversation header, etc.).
  def avatar_for(user, size: 8)
    dimension = "h-#{size} w-#{size}"
    if user&.avatar&.attached?
      image_tag user.avatar.variant(resize_to_fill: [size * 8, size * 8]),
                class: "#{dimension} shrink-0 rounded-full object-cover ring-2 ring-white"
    else
      content_tag :div, (user&.first_name&.first || "U").upcase,
                  class: "#{dimension} shrink-0 flex items-center justify-center rounded-full bg-indigo-100 text-indigo-700 font-semibold ring-2 ring-white text-xs"
    end
  end
end
