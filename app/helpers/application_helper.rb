module ApplicationHelper
  STATUS_BADGE_COLORS = {
    # Prospect statuses
    "new_prospect"  => "bg-sky-100 text-sky-700",
    "contacted"     => "bg-sky-100 text-sky-700",
    "qualified"     => "bg-green-100 text-green-700",
    "disqualified"  => "bg-red-100 text-red-700",
    "converted"     => "bg-violet-100 text-violet-700",
    # Customer statuses
    "active"        => "bg-green-100 text-green-700",
    "inactive"      => "bg-slate-100 text-slate-600",
    "at_risk"       => "bg-amber-100 text-amber-700",
    # Proposal statuses
    "draft"         => "bg-slate-100 text-slate-600",
    "sent"          => "bg-sky-100 text-sky-700",
    "under_review"  => "bg-amber-100 text-amber-700",
    "won"           => "bg-green-100 text-green-700",
    "lost"          => "bg-red-100 text-red-700",
    "cancelled"     => "bg-slate-100 text-slate-600",
    # Task statuses
    "open"          => "bg-amber-100 text-amber-700",
    "in_progress"   => "bg-sky-100 text-sky-700",
    "done"          => "bg-green-100 text-green-700"
  }.freeze

  ROLE_BADGE_COLORS = {
    "admin"      => "bg-violet-100 text-violet-700",
    "consultant" => "bg-indigo-100 text-indigo-700",
    "pending"    => "bg-amber-100 text-amber-700"
  }.freeze

  def user_display_name(user)
    user&.display_name || "Unknown"
  end

  def role_badge(user)
    color = ROLE_BADGE_COLORS.fetch(user.role, "bg-slate-100 text-slate-600")
    tag.span(user.role.capitalize, class: "inline-block px-2 py-1 text-xs font-semibold rounded-full #{color}")
  end

  def status_badge(status, active: true)
    return tag.span("Deactivated", class: "inline-block px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800") unless active

    color = STATUS_BADGE_COLORS.fetch(status.to_s, "bg-slate-100 text-slate-600")
    tag.span(status.to_s.titleize, class: "inline-block px-2 py-1 text-xs font-semibold rounded-full #{color}")
  end

  def sidebar_link(label, path, section = nil)
    active = current_page?(path)
    base = "group flex items-center px-3 py-2 text-sm font-medium rounded-md"
    classes = active ? "#{base} bg-slate-500 text-white" : "#{base} text-slate-200 hover:bg-slate-600 hover:text-white"
    link_to label, path, class: classes
  end

  def currency(amount)
    number_to_currency(amount || 0, unit: "$", precision: 2)
  end
end
