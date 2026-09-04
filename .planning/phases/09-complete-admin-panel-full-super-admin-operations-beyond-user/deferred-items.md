# Deferred Items — Phase 09

Pre-existing (out-of-scope) spec failures observed while running `bundle exec rspec spec/models`
during 09-01 execution. Confirmed present before this plan's model changes (task_spec.rb,
message_spec.rb, task_escrow_lifecycle_spec.rb) — not caused by 09-01's Task/User/Category edits.
Not fixed here per scope boundary (unrelated to admin panel foundation work).

- `spec/models/message_spec.rb:22` — `Message#filtered_content` PII masking when task assigned
- `spec/models/task_escrow_lifecycle_spec.rb:27` — auto-deposit to escrow on payment completion
- `spec/models/task_escrow_lifecycle_spec.rb:42` — allows moving to in_progress after payment
- `spec/models/task_escrow_lifecycle_spec.rb:51` — auto-release escrow on completion
  (root cause: `DoubleEntry::Locking::LockMustBeOutermostTransaction`)
- `spec/models/task_spec.rb:101,106` — `#check_in!` wrong number of arguments (2 given, 0 expected)
- `spec/models/task_spec.rb:115,121` — completion guards not raising `AASM::InvalidTransition`
  (commented-out guards in `Task#complete` event — likely intentional per in-code TODO)
