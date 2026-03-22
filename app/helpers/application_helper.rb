module ApplicationHelper
  def user_display_name(user)
    user&.display_name || "Unknown"
  end

  def role_badge(user)
    color = case user.role
    when "admin" then "bg-purple-100 text-purple-800"
    when "consultant" then "bg-blue-100 text-blue-800"
    when "pending" then "bg-yellow-100 text-yellow-800"
    end

    tag.span(user.role.capitalize, class: "inline-block px-2 py-1 text-xs font-semibold rounded-full #{color}")
  end

  def status_badge(status, active: true)
    return tag.span("Deactivated", class: "inline-block px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800") unless active

    tag.span(status.to_s.titleize, class: "inline-block px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-800")
  end
end
