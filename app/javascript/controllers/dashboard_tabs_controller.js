import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["teamPanel", "minePanel", "teamTab", "mineTab"]

  showTeam() {
    this.teamPanelTarget.hidden = false
    this.minePanelTarget.hidden = true
    this.teamTabTarget.setAttribute("aria-selected", "true")
    this.mineTabTarget.setAttribute("aria-selected", "false")
  }

  showMine() {
    this.minePanelTarget.hidden = false
    this.teamPanelTarget.hidden = true
    this.mineTabTarget.setAttribute("aria-selected", "true")
    this.teamTabTarget.setAttribute("aria-selected", "false")
  }
}
