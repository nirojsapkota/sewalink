import { Controller } from "@hotwired/stimulus";

// Manages the conversation panel: keeps the message list scrolled to the
// latest message, and keeps focus on the composer input so replies can be
// sent back-to-back without re-clicking into the field. Bubble styling
// (sender vs. recipient) is rendered server-side in messages/_message.
export default class extends Controller {
  static targets = ["messages", "input"];

  connect() {
    this.scrollToBottom();

    this.observer = new MutationObserver(() => {
      this.scrollToBottom();
      this.focusInput();
    });
    this.observer.observe(this.messagesTarget, { childList: true });
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
  }

  focusInput() {
    if (this.hasInputTarget && document.activeElement !== this.inputTarget) {
      this.inputTarget.focus();
    }
  }
}
