import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  preview() {
    const files = this.inputTarget.files
    this.previewTarget.innerHTML = ""

    Array.from(files).forEach(file => {
      if (file.type.startsWith("image/")) {
        const img = document.createElement("img")
        img.src = URL.createObjectURL(file)
        img.classList.add("w-24", "h-24", "object-cover", "rounded", "mr-2", "mb-2")
        // Clean up memory
        img.onload = () => { URL.revokeObjectURL(img.src) }
        this.previewTarget.appendChild(img)
      }
    })
  }
}
