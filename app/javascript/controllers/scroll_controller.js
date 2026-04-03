import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.scrollToBottom()
    this.observeNewMessages()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  observeNewMessages() {
    this.observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        if (mutation.addedNodes.length > 0) {
          this.scrollToBottom()
        }
      }
    })
    this.observer.observe(this.element, { childList: true })
  }
}
