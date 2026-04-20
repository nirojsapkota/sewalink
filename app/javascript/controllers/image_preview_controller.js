import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  connect() {
    console.log("ImagePreviewController is connected");
  }

  preview() {
    const files = this.inputTarget.files
    this.previewTarget.innerHTML = ""

    Array.from(files).forEach(file => {
      if (file.type.startsWith("image/")) {
        const reader = new FileReader();
        reader.onload = (e) => {
          const div = document.createElement("div");
          div.className = "relative group animate-in fade-in zoom-in duration-300";
          
          const img = document.createElement("img");
          img.src = e.target.result;
          img.className = "w-full aspect-square object-cover rounded-xl border-2 border-gray-100 shadow-sm group-hover:border-[#7C3AED]/30 transition-all";
          
          div.appendChild(img);
          this.previewTarget.appendChild(div);
        };
        reader.readAsDataURL(file);
      }
    });
  }
}
