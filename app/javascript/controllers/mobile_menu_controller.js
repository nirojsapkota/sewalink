import { Controller } from "@hotwired/stimulus";

// Toggles the mobile navigation panel and keeps the hamburger/close icons
// and aria-expanded state in sync.
export default class extends Controller {
  static targets = ["panel", "openIcon", "closeIcon"];

  toggle() {
    const isHidden = this.panelTarget.classList.contains("hidden");
    this.panelTarget.classList.toggle("hidden", !isHidden);
    this.openIconTarget.classList.toggle("hidden", isHidden);
    this.closeIconTarget.classList.toggle("hidden", !isHidden);
    this.element.setAttribute("aria-expanded", isHidden ? "true" : "false");
  }

  close() {
    this.panelTarget.classList.add("hidden");
    this.openIconTarget.classList.remove("hidden");
    this.closeIconTarget.classList.add("hidden");
    this.element.setAttribute("aria-expanded", "false");
  }
}
