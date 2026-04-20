import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("SearchController is connected");
    this.timeout = null
  }

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.querySelector("form").requestSubmit()
    }, 300)
  }
}
