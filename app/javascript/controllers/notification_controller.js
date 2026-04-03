import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { conversationId: Number }

  connect() {
    this.observeNewMessages()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  observeNewMessages() {
    const messagesContainer = document.getElementById("messages")
    if (!messagesContainer) return

    this.observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        for (const node of mutation.addedNodes) {
          if (node.nodeType === Node.ELEMENT_NODE && node.classList.contains("flex")) {
            // Check if the message is inbound (justify-start)
            if (node.classList.contains("justify-start")) {
              this.notifyNewMessage(node)
            }
          }
        }
      }
    })
    this.observer.observe(messagesContainer, { childList: true })
  }

  notifyNewMessage(node) {
    if (document.hidden && Notification.permission === "granted") {
      const content = node.querySelector(".whitespace-pre-wrap")?.textContent || "New message"
      new Notification("New message", {
        body: content.trim().substring(0, 100),
        tag: `conversation-${this.conversationIdValue}`
      })
    }
    this.playSound()
  }

  playSound() {
    const audio = document.getElementById("notification-sound")
    if (audio) {
      audio.currentTime = 0
      audio.play().catch(() => {})
    }
  }
}
