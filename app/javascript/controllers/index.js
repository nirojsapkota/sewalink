import { application } from "controllers/application"

import ChatController from "controllers/chat_controller"
application.register("chat", ChatController)

import ConfirmationController from "controllers/confirmation_controller"
application.register("confirmation", ConfirmationController)

import GeolocationController from "controllers/geolocation_controller"
application.register("geolocation", GeolocationController)

import ImagePreviewController from "controllers/image_preview_controller"
application.register("image-preview", ImagePreviewController)

import RealTimeChatController from "controllers/real_time_chat_controller"
application.register("real-time-chat", RealTimeChatController)

import SearchController from "controllers/search_controller"
application.register("search", SearchController)

import ToastController from "controllers/toast_controller"
application.register("toast", ToastController)

import VoiceAssistantController from "controllers/voice_assistant_controller"
application.register("voice-assistant", VoiceAssistantController)

import VoiceRecorderController from "controllers/voice_recorder_controller"
application.register("voice-recorder", VoiceRecorderController)
