import "@hotwired/turbo-rails"
import "controllers"

// Temporary removal of charts to isolate the 404 error issue
// import "chartkick"
// import "chart.js"

window.APPLICATION_LOADED = true;
console.log("APPLICATION.JS: Core loaded (Charts disabled for debugging)");
