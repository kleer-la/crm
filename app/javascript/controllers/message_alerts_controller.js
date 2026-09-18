import { Controller } from "@hotwired/stimulus"

// App-wide: alerts the signed-in user to new messages on conversations
// assigned to them, regardless of which page they're currently on.
export default class extends Controller {
  static targets = ["banner", "feed"]

  connect() {
    this.showBannerIfNeeded()
    this.observeFeed()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  showBannerIfNeeded() {
    if (this.hasBannerTarget && "Notification" in window && Notification.permission === "default") {
      this.bannerTarget.classList.remove("hidden")
    }
  }

  requestPermission() {
    Notification.requestPermission().then(() => this.bannerTarget.remove())
  }

  observeFeed() {
    if (!this.hasFeedTarget) return

    this.observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        for (const node of mutation.addedNodes) {
          if (node.nodeType === Node.ELEMENT_NODE) this.alert(node)
        }
      }
    })
    this.observer.observe(this.feedTarget, { childList: true })
  }

  alert(node) {
    const { conversationPath, sender, content } = node.dataset
    const viewingThisConversation = window.location.pathname === conversationPath

    this.playSound()
    if (!viewingThisConversation) {
      this.showDesktopNotification(conversationPath, sender, content)
    }
    node.remove()
  }

  showDesktopNotification(conversationPath, sender, content) {
    if (!("Notification" in window) || Notification.permission !== "granted") return

    const notification = new Notification(sender || "New message", { body: content, tag: conversationPath })
    notification.onclick = () => {
      window.focus()
      Turbo.visit(conversationPath)
      notification.close()
    }
  }

  playSound() {
    const audio = document.getElementById("notification-sound")
    if (audio) {
      audio.currentTime = 0
      audio.play().catch(() => {})
    }
  }
}
