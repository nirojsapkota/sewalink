---
created: 2026-04-15T14:45:00Z
title: Fix blank task detail page and hide locale param from URLs
area: ui
files:
  - app/views/tasks/show.html.erb
  - app/controllers/application_controller.rb
  - config/routes.rb
---

## Problem

1. **Blank Task Detail Page**: When viewing the detail page of a task (`tasks#show`), it's not displaying anything. The user suggests it might be an issue with Turbo/Turbolinks.
2. **Visible Locale Parameter**: The `locale` parameter (e.g., `?locale=en`) is visible on all links and URLs. The user wants this hidden or handled more transparently.

## Solution

1. **Investigate Task Show View**:
    - Check for JavaScript errors in the console that might be breaking Turbo rendering.
    - Verify that the `show` view and any partials it renders (like `_task.html.erb` or `_task_actions.html.erb`) are rendering correctly on the server.
    - Check if recent Turbo Stream changes (from Phase 6) are interfering with the initial page load.

2. **Handle Locale More Elegantly**:
    - Move locale persistence from the URL query parameter to the session or a cookie if the user wants it completely "hidden".
    - Alternatively, use URL path prefixes (e.g., `/en/tasks/1`) and ensure `default_url_options` doesn't leak it as a query param if not needed.
    - Update `ApplicationController` to set the locale from the chosen source.
