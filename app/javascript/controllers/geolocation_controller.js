import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { taskId: Number, taskLatitude: Number, taskLongitude: Number }
  static targets = ["geofenceStatus", "markDoneButton", "checkInButton"]

  // Debounce timeout for geofence checks (e.g., 2 seconds)
  geofenceCheckTimeout = null;
  // debounceDelay = 2000; // milliseconds - no longer needed for single shot

  connect() {
    if (navigator.geolocation) {
      this.geofenceStatusTarget.textContent = "Checking location...";
      // Perform an initial check on connect
      this.fetchCurrentPosition();
    } else {
      this.geofenceStatusTarget.textContent = "Geolocation is not supported by your browser.";
      this.disableMarkDoneButton();
      this.disableCheckInButton("Geolocation not supported.");
    }
  }

  disconnect() {
    // No longer watching, so no need to clearWatch
    if (this.geofenceCheckTimeout) {
      clearTimeout(this.geofenceCheckTimeout);
    }
  }

  // Renamed from startWatchingLocation, now performs a single fetch
  fetchCurrentPosition() {
    const options = {
      enableHighAccuracy: true,
      timeout: 5000,
      maximumAge: 0
    };
    navigator.geolocation.getCurrentPosition(
      this.positionSuccess.bind(this),
      this.positionError.bind(this),
      options
    );
  }

  positionSuccess(position) {
    const { latitude, longitude } = position.coords;
    // For single-shot fetch, call checkGeofence directly without debounce
    this.checkGeofence(latitude, longitude);
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
    this.disableCheckInButton(errorMessage);
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
      this.disableCheckInButton("Error checking geofence status.");
    }
  }

  checkIn() {
    this.geofenceStatusTarget.textContent = "Attempting check-in...";
    const options = {
      enableHighAccuracy: true,
      timeout: 5000,
      maximumAge: 0
    };
    navigator.geolocation.getCurrentPosition(
      (position) => this.performCheckIn(position.coords.latitude, position.coords.longitude),
      this.positionError.bind(this), // Reuse existing error handler
      options
    );
  }

  async performCheckIn(currentLatitude, currentLongitude) {
    const url = `/tasks/${this.taskIdValue}/perform_check_in`;
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

      const data = await response.json();

      if (response.ok) {
        this.geofenceStatusTarget.innerHTML = `<span class="text-green-600 font-semibold">${data.message}</span>`;
        // After successful check-in, the task status might change (e.g., to 'in_progress').
        // Re-fetching the task data or using Turbo Streams would be ideal here to update UI components
        // based on the new task status (e.g., disable check-in button).
        // For now, re-check geofence status to update button states based on new task_status
        this.checkGeofence(currentLatitude, currentLongitude);
      } else {
        this.geofenceStatusTarget.innerHTML = `<span class="text-red-600 font-semibold">${data.message}</span>`;
        // If check-in fails, re-check geofence status to update button states (e.g., check-in button remains disabled)
        this.checkGeofence(currentLatitude, currentLongitude);
      }
    } catch (error) {
      console.error("Error performing check-in:", error);
      this.geofenceStatusTarget.textContent = "Error during check-in.";
    }
  }

  updateGeofenceStatus(data) {
    if (data.within_geofence) {
      this.geofenceStatusTarget.innerHTML = `<span class="text-green-600 font-semibold">You are within geofence (< ${Math.round(data.distance)}m).</span>`;
      this.enableMarkDoneButton();
      if (data.task_status === 'assigned') {
        this.enableCheckInButton();
      } else {
        this.disableCheckInButton("Task is not in 'assigned' status.");
      }
    } else {
      this.geofenceStatusTarget.innerHTML = `<span class="text-red-600 font-semibold">You are outside geofence (~ ${Math.round(data.distance)}m).</span>`;
      this.disableMarkDoneButton();
      this.disableCheckInButton("You are outside the geofence.");
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

  disableCheckInButton(reason = "") {
    if (this.hasCheckInButtonTarget) {
      this.checkInButtonTarget.disabled = true;
      this.checkInButtonTarget.classList.add("opacity-50", "cursor-not-allowed");
      this.checkInButtonTarget.title = reason;
    }
  }

  enableCheckInButton() {
    if (this.hasCheckInButtonTarget) {
      this.checkInButtonTarget.disabled = false;
      this.checkInButtonTarget.classList.remove("opacity-50", "cursor-not-allowed");
      this.checkInButtonTarget.title = "";
    }
  }

}
