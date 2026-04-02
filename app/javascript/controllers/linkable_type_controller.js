import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  change(event) {
    const type = event.target.value
    const frame = document.getElementById("linkable_id_select")
    if (!frame) return

    if (type) {
      frame.src = `${this.urlValue}?linkable_type=${encodeURIComponent(type)}`
    } else {
      frame.src = this.urlValue
    }
  }
}
