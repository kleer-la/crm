import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "messageType", "noteToggle", "submit", "fileInput", "filePreview", "fileName", "fileButton"]

  connect() {
    this.noteMode = false
  }

  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.inputTarget.value.trim() || this.fileInputTarget.files.length > 0) {
        this.formTarget.requestSubmit()
        this.inputTarget.value = ""
        this.resize()
        this.clearFile()
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
      this.fileButtonTarget.classList.add("hidden")
    } else {
      this.messageTypeTarget.value = "text"
      this.noteToggleTarget.classList.remove("bg-amber-100", "text-amber-700")
      this.noteToggleTarget.classList.add("text-slate-500")
      this.submitTarget.textContent = "Send"
      this.inputTarget.placeholder = "Type a message..."
      this.fileButtonTarget.classList.remove("hidden")
    }
  }

  pickFile() {
    this.fileInputTarget.click()
  }

  fileSelected() {
    const file = this.fileInputTarget.files[0]
    if (file) {
      this.fileNameTarget.textContent = file.name
      this.filePreviewTarget.classList.remove("hidden")
      this.filePreviewTarget.classList.add("flex")

      // Auto-detect message type from file
      if (file.type.startsWith("image/")) {
        this.messageTypeTarget.value = "image"
      } else if (file.type.startsWith("video/")) {
        this.messageTypeTarget.value = "video"
      } else if (file.type.startsWith("audio/")) {
        this.messageTypeTarget.value = "audio"
      } else {
        this.messageTypeTarget.value = "document"
      }
    }
  }

  clearFile() {
    this.fileInputTarget.value = ""
    this.filePreviewTarget.classList.add("hidden")
    this.filePreviewTarget.classList.remove("flex")
    if (!this.noteMode) {
      this.messageTypeTarget.value = "text"
    }
  }
}
