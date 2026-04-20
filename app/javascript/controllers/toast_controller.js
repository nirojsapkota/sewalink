import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    console.log("ToastController is connected");
    // Automatically close after 5 seconds
    this.timeout = setTimeout(() => {
      this.close()
    }, 5000)
  }

  close() {
    if (this.hasContainerTarget) {
      this.containerTarget.classList.add("translate-x-full", "opacity-0")
      setTimeout(() => {
        this.element.remove()
      }, 500)
    } else {
      this.element.remove()
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
}
