import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.scrollToBottom();

    // Keep the conversation scrolled to the latest message as new ones
    // arrive via Turbo Streams. Bubble styling (sender vs. recipient) is
    // rendered server-side in messages/_message, so no JS styling pass is
    // needed here.
    this.observer = new MutationObserver(() => this.scrollToBottom());
    this.observer.observe(this.element, { childList: true });
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight;
  }
}
