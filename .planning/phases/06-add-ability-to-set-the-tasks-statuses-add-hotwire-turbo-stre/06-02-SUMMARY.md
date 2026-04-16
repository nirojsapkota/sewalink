# Phase 06-02: Status Transition Actions & UI Buttons

## Completed Work
1. **Routes**:
    - Added member routes for `request_payment`, `release_payment`, `raise_dispute` (POST) and `toggle_draft` (PATCH) to `resources :tasks`.
2. **Authorization**:
    - Updated `TaskPolicy` with granular rules:
        - `request_payment?`: Tasker only, when `in_progress`.
        - `release_payment?`: Poster only, when `pending_payment`.
        - `raise_dispute?`: Both roles, in most active states.
        - `toggle_draft?`: Poster only, when `draft` or `open`.
3. **Controller Actions**:
    - Implemented `TasksController#request_payment`, `release_payment`, `raise_dispute`, and `toggle_draft`.
    - Integrated `release_payment` with `release_payment!` which triggers the model's `after_commit` hook for escrow release.
    - Added flash messages for successful/failed transitions.
4. **UI Buttons**:
    - Created `app/views/tasks/_task_actions.html.erb` with conditional buttons based on policy and state.
    - Integrated partial into `app/views/tasks/show.html.erb`.
    - Added `turbo_confirm` to critical actions (Request/Release Payment, Dispute).
5. **Testing Infrastructure**:
    - Updated `spec/rails_helper.rb` to include `Devise::Test::IntegrationHelpers` for system tests.
    - Configured `WebMock` to allow localhost connections for Capybara.
    - Updated `spec/factories/users.rb` to default to `onboarded: true` for smoother testing.

## Verification
- **Request Specs**: `spec/requests/tasks_status_spec.rb` passed (8 examples). Verified authorization and redirects (handling locale parameters).
- **System Specs**: `spec/system/task_status_system_spec.rb` passed (4 examples). Verified that buttons appear and function correctly in the browser for both Posters and Taskers.

## Next Steps
- Move to Wave 3 (Plan 06-03): Implement real-time UI updates and background notifications with Turbo Streams.
