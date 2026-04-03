import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "messageType", "noteToggle", "submit"]

  connect() {
    this.noteMode = false
  }

  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.inputTarget.value.trim()) {
        this.formTarget.requestSubmit()
        this.inputTarget.value = ""
        this.resize()
      }
    }
  }

  resize() {
    this.inputTarget.style.height = "auto"
    this.inputTarget.style.height = Math.min(this.inputTarget.scrollHeight, 120) + "px"
  }

  toggleNote() {
    this.noteMode = !this.noteMode
    if (this.noteMode) {
      this.messageTypeTarget.value = "note"
      this.noteToggleTarget.classList.add("bg-amber-100", "text-amber-700")
      this.noteToggleTarget.classList.remove("text-slate-500")
      this.submitTarget.textContent = "Save note"
      this.inputTarget.placeholder = "Type an internal note..."
    } else {
      this.messageTypeTarget.value = "text"
      this.noteToggleTarget.classList.remove("bg-amber-100", "text-amber-700")
      this.noteToggleTarget.classList.add("text-slate-500")
      this.submitTarget.textContent = "Send"
      this.inputTarget.placeholder = "Type a message..."
    }
  }
}
