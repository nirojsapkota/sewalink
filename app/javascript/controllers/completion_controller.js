import { Controller } from "@hotwired/stimulus";

// Gates the "Mark as Done" submit button on the task completion form behind
// a geolocation check for on-site tasks: the tasker must be within the task's
// geofence (verified server-side against Task#within_geofence?) before they
// can submit. Populates hidden lat/lng fields so the server can re-verify.
export default class extends Controller {
  static values = { onSite: Boolean };
  static targets = ["form", "geofenceStatus", "latitude", "longitude", "submitButton"];

  connect() {
    if (!this.onSiteValue) return;

    if (navigator.geolocation) {
      this.geofenceStatusTarget.textContent = "Checking your location...";
      navigator.geolocation.getCurrentPosition(
        this.positionSuccess.bind(this),
        this.positionError.bind(this),
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
      );
    } else {
      this.geofenceStatusTarget.textContent = "Geolocation is not supported by your browser.";
    }
  }

  positionSuccess(position) {
    const { latitude, longitude } = position.coords;
    this.latitudeTarget.value = latitude;
    this.longitudeTarget.value = longitude;
    this.geofenceStatusTarget.innerHTML = `<span class="text-green-600 font-semibold">Location confirmed. You can submit completion.</span>`;
    this.enableSubmit();
  }

  positionError() {
    this.geofenceStatusTarget.innerHTML = `<span class="text-red-600 font-semibold">We couldn't confirm your location. Enable location access and reload the page.</span>`;
  }

  enableSubmit() {
    if (!this.hasSubmitButtonTarget) return;
    this.submitButtonTarget.disabled = false;
    this.submitButtonTarget.classList.remove("opacity-50", "cursor-not-allowed");
  }
}
