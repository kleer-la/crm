import { Controller } from "@hotwired/stimulus"

// Renders a server-supplied UTC timestamp in the viewer's own browser timezone.
export default class extends Controller {
  static values = { iso: String }

  connect() {
    const date = new Date(this.isoValue)
    if (isNaN(date)) return

    const datePart = new Intl.DateTimeFormat(undefined, { month: "short", day: "numeric" }).format(date)
    const timePart = new Intl.DateTimeFormat(undefined, { hour: "2-digit", minute: "2-digit", hour12: false }).format(date)
    this.element.textContent = `${datePart}, ${timePart}`
  }
}
