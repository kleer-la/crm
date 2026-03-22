import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "mobile"]

  toggle() {
    this.overlayTarget.classList.toggle("hidden")
  }

  close() {
    this.overlayTarget.classList.add("hidden")
  }
}
