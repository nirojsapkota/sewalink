import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)

import GeolocationController from "./geolocation_controller"
application.register("geolocation", GeolocationController)

