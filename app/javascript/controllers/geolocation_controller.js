import { Controller } from "@hotwired/stimulus";

// Handles the "Check In & Start Task" flow for on-site tasks: watches the
// tasker's location, verifies they are within the task's geofence, and lets
// them check in (POST /tasks/:id/perform_check_in) to transition the task
// from `assigned` to `in_progress`. Remote (non on-site) tasks skip the
// geolocation requirement entirely.
export default class extends Controller {
  static values = { taskId: Number, taskLatitude: Number, taskLongitude: Number, onSite: Boolean };
  static targets = ["geofenceStatus", "checkInButton"];

  debounceDelay = 2000; // milliseconds
  geofenceCheckTimeout = null;
  lastPosition = null;

  connect() {
    if (!this.onSiteValue) return; // remote tasks: button is already enabled in the view

    if (navigator.geolocation) {
      if (this.hasGeofenceStatusTarget) {
        this.geofenceStatusTarget.textContent = "Checking your location...";
      }
      this.startWatchingLocation();
    } else if (this.hasGeofenceStatusTarget) {
      this.geofenceStatusTarget.textContent = "Geolocation is not supported by your browser.";
      this.disableCheckInButton();
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
    const options = { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 };
    this.watchId = navigator.geolocation.watchPosition(
      this.positionSuccess.bind(this),
      this.positionError.bind(this),
      options
    );
  }

  positionSuccess(position) {
    const { latitude, longitude } = position.coords;
    this.lastPosition = { latitude, longitude };
    if (this.geofenceCheckTimeout) clearTimeout(this.geofenceCheckTimeout);
    this.geofenceCheckTimeout = setTimeout(() => this.checkGeofence(latitude, longitude), this.debounceDelay);
  }

  positionError(error) {
    let errorMessage = "Location unavailable.";
    switch (error.code) {
      case error.PERMISSION_DENIED:
        errorMessage = "Location access denied. Please enable it in your browser settings to check in.";
        break;
      case error.POSITION_UNAVAILABLE:
        errorMessage = "Location information is unavailable.";
        break;
      case error.TIMEOUT:
        errorMessage = "Location request timed out.";
        break;
    }
    if (this.hasGeofenceStatusTarget) this.geofenceStatusTarget.textContent = errorMessage;
    this.disableCheckInButton();
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
        body: JSON.stringify({ current_latitude: currentLatitude, current_longitude: currentLongitude })
      });

      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

      const data = await response.json();
      this.updateGeofenceStatus(data);
    } catch (error) {
      if (this.hasGeofenceStatusTarget) this.geofenceStatusTarget.textContent = "Error checking your location. Please try again.";
      this.disableCheckInButton();
    }
  }

  updateGeofenceStatus(data) {
    if (!this.hasGeofenceStatusTarget) return;

    if (data.within_geofence) {
      this.geofenceStatusTarget.innerHTML = `<span class="text-green-600 font-semibold">You are within range (~${Math.round(data.distance)}m). You can check in now.</span>`;
      this.enableCheckInButton();
    } else {
      this.geofenceStatusTarget.innerHTML = `<span class="text-red-600 font-semibold">You are outside the task location (~${Math.round(data.distance)}m away). Move closer to check in.</span>`;
      this.disableCheckInButton();
    }
  }

  disableCheckInButton() {
    if (!this.hasCheckInButtonTarget) return;
    this.checkInButtonTarget.disabled = true;
    this.checkInButtonTarget.classList.add("opacity-50", "cursor-not-allowed");
  }

  enableCheckInButton() {
    if (!this.hasCheckInButtonTarget) return;
    this.checkInButtonTarget.disabled = false;
    this.checkInButtonTarget.classList.remove("opacity-50", "cursor-not-allowed");
  }

  async checkIn(event) {
    event.preventDefault();
    if (this.hasCheckInButtonTarget) {
      this.checkInButtonOriginalText ||= this.checkInButtonTarget.textContent;
      this.checkInButtonTarget.disabled = true;
      this.checkInButtonTarget.textContent = "Checking in...";
    }

    const body = { current_latitude: 0, current_longitude: 0 };
    if (this.onSiteValue) {
      if (!this.lastPosition) {
        this.restoreCheckInButton();
        return;
      }
      body.current_latitude = this.lastPosition.latitude;
      body.current_longitude = this.lastPosition.longitude;
    }

    try {
      const response = await fetch(`/tasks/${this.taskIdValue}/perform_check_in`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify(body)
      });

      const data = await response.json();
      if (response.ok && data.success) {
        window.location.reload();
      } else {
        alert(data.message || "Could not check in. Please try again.");
        this.restoreCheckInButton();
      }
    } catch (error) {
      alert("Network error while checking in. Please try again.");
      this.restoreCheckInButton();
    }
  }

  restoreCheckInButton() {
    if (!this.hasCheckInButtonTarget) return;
    this.checkInButtonTarget.disabled = false;
    this.checkInButtonTarget.textContent = this.checkInButtonOriginalText || "Check In & Start Task";
  }
}
