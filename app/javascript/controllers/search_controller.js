import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      if (query.length >= 2) {
        this.showResults()
        this.inputTarget.form.requestSubmit()
      } else {
        this.hideResults()
      }
    }, 300)
  }

  showResults() {
    this.resultsTarget.classList.remove("hidden")
  }

  hideResults() {
    this.resultsTarget.classList.add("hidden")
  }

  delayHideResults() {
    setTimeout(() => this.hideResults(), 200)
  }

  navigate(event) {
    event.preventDefault()
    window.location.href = event.currentTarget.href
  }
}
