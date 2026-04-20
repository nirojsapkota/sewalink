import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  zoom(event) {
    const src = event.currentTarget.src
    const overlay = document.createElement("div")
    overlay.className = "fixed inset-0 z-50 flex items-center justify-center bg-black/90 p-4 cursor-zoom-out animate-in fade-in duration-200"
    
    const img = document.createElement("img")
    img.src = src
    img.className = "max-w-full max-h-full rounded-lg shadow-2xl animate-in zoom-in-95 duration-200"
    
    overlay.onclick = () => {
      overlay.classList.add("fade-out")
      setTimeout(() => overlay.remove(), 200)
    }
    
    // Add close button
    const close = document.createElement("button")
    close.innerHTML = "&times;"
    close.className = "absolute top-4 right-6 text-white text-4xl font-light hover:text-gray-300 transition-colors"
    
    overlay.appendChild(img)
    overlay.appendChild(close)
    document.body.appendChild(overlay)
  }
}
