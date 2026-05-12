import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("turbo:frame-load", this.#onFrameLoad)
  }

  disconnect() {
    this.element.removeEventListener("turbo:frame-load", this.#onFrameLoad)
  }

  close() {
    const dialog = this.element.querySelector("dialog")
    if (dialog) dialog.close()
  }

  #onFrameLoad = () => {
    const dialog = this.element.querySelector("dialog")
    if (!dialog) return
    dialog.addEventListener("click", this.#onBackdropClick)
    dialog.addEventListener("close", this.#onClose)
    dialog.showModal()
  }

  // Close when clicking the backdrop (the <dialog> element itself, outside the content panel)
  #onBackdropClick = (event) => {
    if (event.target.nodeName === "DIALOG") {
      event.target.close()
    }
  }

  // Clear the frame when the dialog closes (ESC, backdrop, or X button)
  #onClose = () => {
    this.element.innerHTML = ""
  }
}
