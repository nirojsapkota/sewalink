import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { taskId: Number, taskLatitude: Number, taskLongitude: Number }
  static targets = ["geofenceStatus", "markDoneButton"]

  // Debounce timeout for geofence checks (e.g., 2 seconds)
  geofenceCheckTimeout = null;
  debounceDelay = 2000; // milliseconds

  connect() {
    if (navigator.geolocation) {
      this.geofenceStatusTarget.textContent = "Checking location...";
      this.startWatchingLocation();
    } else {
      this.geofenceStatusTarget.textContent = "Geolocation is not supported by your browser.";
      this.disableMarkDoneButton();
    }
  }

  disconnect() {
    if (this.watchId) {
      navigator.geolocation.clearWatch(this.watchId);
    }
    if (this.geofenceCheckTimeout) {
      clearTimeout(this.geofenceCheckTimeout);
    }
  }

  startWatchingLocation() {
    const options = {
      enableHighAccuracy: true,
      timeout: 5000,
      maximumAge: 0
    };
    this.watchId = navigator.geolocation.watchPosition(
      this.positionSuccess.bind(this),
      this.positionError.bind(this),
      options
    );
  }

  positionSuccess(position) {
    const { latitude, longitude } = position.coords;
    // Debounce the geofence check
    if (this.geofenceCheckTimeout) {
      clearTimeout(this.geofenceCheckTimeout);
    }
    this.geofenceCheckTimeout = setTimeout(() => {
      this.checkGeofence(latitude, longitude);
    }, this.debounceDelay);
  }

  positionError(error) {
    console.error("Geolocation error:", error);
    let errorMessage = "Geolocation unavailable.";
    switch(error.code) {
      case error.PERMISSION_DENIED:
        errorMessage = "Location access denied. Please enable it in your browser settings.";
        break;
      case error.POSITION_UNAVAILABLE:
        errorMessage = "Location information is unavailable.";
        break;
      case error.TIMEOUT:
        errorMessage = "Location request timed out.";
        break;
    }
    this.geofenceStatusTarget.textContent = errorMessage;
    this.disableMarkDoneButton();
  }

  async checkGeofence(currentLatitude, currentLongitude) {
    const url = `/tasks/${this.taskIdValue}/check_geofence`;
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({
          task_id: this.taskIdValue,
          current_latitude: currentLatitude,
          current_longitude: currentLongitude
        })
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      this.updateGeofenceStatus(data);

    } catch (error) {
      console.error("Error checking geofence:", error);
      this.geofenceStatusTarget.textContent = "Error checking geofence status.";
      this.disableMarkDoneButton();
    }
  }

  updateGeofenceStatus(data) {
    if (data.within_geofence) {
      this.geofenceStatusTarget.innerHTML = `<span class="text-green-600 font-semibold">You are within geofence (< ${Math.round(data.distance)}m).</span>`;
      this.enableMarkDoneButton();
      if (data.auto_checked_in) {
        // Optionally, trigger a Turbo Stream update for the task status
        // Turbo.visit(window.location.href, { action: "replace" });
      }
    } else {
      this.geofenceStatusTarget.innerHTML = `<span class="text-red-600 font-semibold">You are outside geofence (~ ${Math.round(data.distance)}m).</span>`;
      this.disableMarkDoneButton();
    }
  }

  disableMarkDoneButton() {
    if (this.hasMarkDoneButtonTarget) {
      this.markDoneButtonTarget.disabled = true;
      this.markDoneButtonTarget.classList.add("opacity-50", "cursor-not-allowed");
      this.markDoneButtonTarget.title = "You must be within the geofence to mark this task as done.";
    }
  }

  enableMarkDoneButton() {
    if (this.hasMarkDoneButtonTarget) {
      this.markDoneButtonTarget.disabled = false;
      this.markDoneButtonTarget.classList.remove("opacity-50", "cursor-not-allowed");
      this.markDoneButtonTarget.title = "";
    }
  }
}
