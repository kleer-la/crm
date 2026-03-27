import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "pills", "option", "noResults", "blank"]

  connect() {
    this.selectedIds = new Set()
    this.highlightedIndex = -1

    this.closeHandler = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.closeHandler)

    // Re-hydrate from any existing hidden inputs (e.g. edit form)
    this.element.querySelectorAll('input[type="hidden"][data-collaborator-id]').forEach(input => {
      this.selectedIds.add(input.dataset.collaboratorId)
    })

    // Mark already-selected options as hidden
    this.optionTargets.forEach(opt => {
      if (this.selectedIds.has(opt.dataset.value)) {
        opt.classList.add("hidden")
      }
    })

    this.updateBlankInput()
  }

  disconnect() {
    document.removeEventListener("click", this.closeHandler)
  }

  // --- Open / close ---

  openDropdown() {
    this.dropdownTarget.classList.remove("hidden")
    this.dropdownTarget.setAttribute("aria-expanded", "true")
    this.highlightedIndex = -1
    this.filter()
  }

  closeDropdown() {
    this.dropdownTarget.classList.add("hidden")
    this.dropdownTarget.setAttribute("aria-expanded", "false")
    this.clearHighlight()
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.closeDropdown()
    }
  }

  onInputClick(event) {
    event.stopPropagation()
    this.openDropdown()
  }

  // --- Filter ---

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    let visibleCount = 0

    this.optionTargets.forEach(opt => {
      if (this.selectedIds.has(opt.dataset.value)) {
        opt.classList.add("hidden")
        return
      }
      const matches = opt.dataset.label.toLowerCase().includes(query)
      opt.classList.toggle("hidden", !matches)
      if (matches) visibleCount++
    })

    this.noResultsTarget.classList.toggle("hidden", visibleCount > 0)
    this.highlightedIndex = -1
    this.clearHighlight()
  }

  onInput() {
    this.openDropdown()
    this.filter()
  }

  // --- Select / Remove ---

  selectOption(event) {
    const opt = event.currentTarget
    this.addSelection(opt.dataset.value, opt.dataset.label)
  }

  addSelection(id, label) {
    if (this.selectedIds.has(id)) return

    this.selectedIds.add(id)

    // Add pill
    const pill = document.createElement("span")
    pill.className = "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800"
    pill.dataset.collaboratorId = id
    pill.innerHTML = `${this.escapeHtml(label)}<button type="button" data-action="click->multi-select#removePill" data-id="${id}" aria-label="Remove ${this.escapeHtml(label)}" class="text-indigo-500 hover:text-indigo-700 leading-none focus:outline-none">&times;</button>`
    this.pillsTarget.appendChild(pill)

    // Add hidden input
    const hiddenInput = document.createElement("input")
    hiddenInput.type = "hidden"
    hiddenInput.name = this.inputTarget.dataset.fieldName
    hiddenInput.value = id
    hiddenInput.dataset.collaboratorId = id
    this.element.appendChild(hiddenInput)

    // Hide option in dropdown
    const opt = this.optionTargets.find(o => o.dataset.value === id)
    if (opt) opt.classList.add("hidden")

    // Clear search and close
    this.inputTarget.value = ""
    this.closeDropdown()
    this.updateBlankInput()
  }

  removePill(event) {
    const id = event.currentTarget.dataset.id
    this.removeSelection(id)
  }

  removeSelection(id) {
    this.selectedIds.delete(id)

    // Remove pill
    const pill = this.pillsTarget.querySelector(`[data-collaborator-id="${id}"]`)
    if (pill) pill.remove()

    // Remove hidden input
    const input = this.element.querySelector(`input[type="hidden"][data-collaborator-id="${id}"]`)
    if (input) input.remove()

    // Restore option in dropdown
    const opt = this.optionTargets.find(o => o.dataset.value === id)
    if (opt) {
      opt.classList.remove("hidden")
      // Re-apply filter if dropdown is open
      if (!this.dropdownTarget.classList.contains("hidden")) this.filter()
    }

    this.updateBlankInput()
  }

  // --- Keyboard navigation ---

  onKeydown(event) {
    const isOpen = !this.dropdownTarget.classList.contains("hidden")

    if (event.key === "ArrowDown") {
      event.preventDefault()
      if (!isOpen) this.openDropdown()
      this.moveHighlight(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.moveHighlight(-1)
    } else if (event.key === "Enter") {
      event.preventDefault()
      const highlighted = this.visibleOptions()[this.highlightedIndex]
      if (highlighted) {
        this.addSelection(highlighted.dataset.value, highlighted.dataset.label)
      }
    } else if (event.key === "Escape") {
      this.closeDropdown()
      this.inputTarget.focus()
    } else if (event.key === "Backspace" && this.inputTarget.value === "") {
      const lastId = [...this.selectedIds].pop()
      if (lastId) this.removeSelection(lastId)
    }
  }

  visibleOptions() {
    return this.optionTargets.filter(o => !o.classList.contains("hidden"))
  }

  moveHighlight(direction) {
    const options = this.visibleOptions()
    if (options.length === 0) return

    this.clearHighlight()
    this.highlightedIndex = Math.max(0, Math.min(
      this.highlightedIndex + direction,
      options.length - 1
    ))
    options[this.highlightedIndex].classList.add("bg-indigo-50")
    options[this.highlightedIndex].scrollIntoView({ block: "nearest" })
  }

  clearHighlight() {
    this.optionTargets.forEach(o => o.classList.remove("bg-indigo-50"))
  }

  // --- Blank input (clears association when nothing selected) ---

  updateBlankInput() {
    if (this.selectedIds.size === 0) {
      if (!this.hasBlankTarget) {
        const blank = document.createElement("input")
        blank.type = "hidden"
        blank.name = this.inputTarget.dataset.fieldName
        blank.value = ""
        blank.dataset.multiSelectTarget = "blank"
        this.element.appendChild(blank)
      }
    } else {
      if (this.hasBlankTarget) {
        this.blankTarget.remove()
      }
    }
  }

  // --- Utility ---

  escapeHtml(str) {
    return str.replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]))
  }
}
