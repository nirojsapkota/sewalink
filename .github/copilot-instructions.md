# sewaLink

Mobile-first Rails marketplace connecting task "posters" with local service "taskers" in Nepal.
Built with Ruby on Rails 7.1 + Hotwire (Turbo/Stimulus, no separate SPA frontend), Tailwind CSS,
PostgreSQL, and eSewa (Nepali payment gateway) for escrow-based payments.

## Setup & running locally

- `bin/setup` — installs gems, prepares the DB, clears logs/tmp, restarts the server.
- `bin/dev` (via `Procfile.dev`) — runs `bin/rails server` + `bin/rails tailwindcss:watch` together.
- `bin/rails db:seed` — creates demo categories and one demo account per role (super_admin,
  poster, tasker), all with phone-based login (see README for credentials). Idempotent — looks
  users up by phone before creating.
- Requires `config/master.key` (gitignored) for encrypted credentials, or set env vars directly
  (e.g. `GEMINI_API_KEY`, `OTP_SECRET_ENCRYPTION_KEY`).

## Tests

RSpec is the active test suite (`spec/`) — it has full coverage of models, requests, policies,
services, and jobs. The `test/` directory (Minitest) is legacy/stale scaffolding; prefer adding
to `spec/` for new work.

- Run all specs: `bundle exec rspec`
- Run one file: `bundle exec rspec spec/models/task_spec.rb`
- Run one example (by line number): `bundle exec rspec spec/models/task_spec.rb:42`
- Factories live in `spec/factories/` (FactoryBot); use `create(:task)`, `create(:user)`, etc.
  in specs rather than instantiating records manually.

There is no CI workflow and no Rubocop config in this repo — don't add linting/CI setup unless
asked.

## Architecture

**Domain model** (`app/models`): `User` (poster/tasker via `active_role` enum, roles via
`rolify`), `Task` (the core entity), `Bid`, `Conversation`/`Message`, `Review`,
`PaymentTransaction`, `PayoutRequest`, `DisputeEvidence`, `Category`, `PlatformSetting`
(singleton-style platform-wide config, e.g. commission rate, geofence toggle).

**Task lifecycle is an explicit state machine** — `Task` uses `aasm` (column `:status`, backed
by a Rails `enum`) with states `draft → open → assigned → in_progress → pending_payment →
payment_completed → completed`, plus `dispute`/`cancelled` side states. Events (`assign!`,
`start_work!`, `complete!`, `raise_dispute!`, etc.) encode the only legal transitions and carry
guards (e.g. `start_work`/`complete` require `within_geofence?`, `complete` also requires
`completion_photo_attached?`). When changing task behavior, add/modify AASM events rather than
writing ad hoc status assignments.

**Geofencing**: tasks optional `on_site` flag + `PlatformSetting.geofence_check_in_enabled?`
gate whether check-in/completion require the tasker's live lat/lng to be within 200m
(`Task#within_geofence?`) of the geocoded task location (via `geocoder`).

**Money & ledgers**: monetary fields use `money-rails` (`monetize :budget_cents`, all amounts
are NPR `Money` objects, not raw integers/floats). Tasker balances and commission bookkeeping go
through `double_entry` (`DoubleEntry.account(:tasker_balance, scope: user)`) for auditable
double-entry accounting — do not mutate balances by hand. `Payments::CommissionCalculator`,
`Payments::LedgerManager`, and `Payments::EsewaV2` (in `app/services/payments/`) are the
canonical entry points for payment/escrow/commission logic; escrow release and cash commission
recording are dispatched as background jobs (`Payments::ReleaseEscrowJob`,
`Payments::RecordCashCommissionJob`) from `Task#release_escrow_if_completed`.

**Accounting** (`app/services/accounting/`): separate from live payments — handles eSewa
settlement CSV import/reconciliation and ledger reporting for admins
(`Admin::Accounting::*Controller`).

**Auth**: Devise with phone number as the login identifier (not email — see
`User#email_required?`), two-factor OTP via `devise-two-factor`/ROTP, OTP delivered by SMS
(`SmsService`) and optionally email. Phone format is validated as a Nepali mobile number
(`/\A9[678]\d{8}\z/`).

**Authorization**: Pundit policies in `app/policies/`, one per resource, subclassing
`ApplicationPolicy` (default-deny — every check returns `false` unless overridden). Use
`policy(record).action?` / `authorize record` in controllers rather than ad hoc role checks.

**Real-time UI**: Hotwire/Turbo Streams broadcast model changes directly from models
(`Task#broadcasts_refreshes`, `after_update_commit :broadcast_status_change`) — status changes
push both a page refresh/partial replace and a per-user toast notification
(`broadcast_prepend_to [recipient, :notifications]`). Prefer broadcasting from the model over
manually rendering partials in controllers/jobs.

**Gemini Live Chat (voice assistant)**: `app/javascript/controllers/real_time_chat_controller.js`
talks directly to Gemini's Live API over WebSocket; there is no MCP server involved. Rails' role
is limited to (1) minting an ephemeral token and serving the tool schema
(`Gemini::TokensController`, tool defs in `app/services/gemini/tool_definitions.rb`) and (2)
executing tool calls the model requests via a fixed `case/when` whitelist
(`Gemini::ToolsController#execute` — only `create_task_draft`, `publish_task`, `query_tasks` are
recognized). See README.md for the full request/response flow.

**i18n**: bilingual English/Nepali app — locale files in `config/locales/` (`en.yml`, `ne.yml`),
and domain data (e.g. seeded categories) carries both `name_en`/`name_ne` fields.

**Deployment**: infra (Terraform: VPC/EC2/EIP) lives in `infra/` and is managed separately from
app deploys. To ship app code changes, run `cd infra && ./redeploy.sh` (SSHes in, `git pull`s
`main`, `docker-compose up -d --build`) — never use `terraform apply` for routine app deploys.

<!-- GSD Configuration — managed by get-shit-done installer -->
# Instructions for GSD

- Use the get-shit-done skill when the user asks for GSD or uses a `gsd-*` command.
- Treat `/gsd-...` or `gsd-...` as command invocations and load the matching file from `.github/skills/gsd-*`.
- When a command says to spawn a subagent, prefer a matching custom agent from `.github/agents`.
- Do not apply GSD workflows unless the user explicitly asks for them.
- After completing any `gsd-*` command (or any deliverable it triggers: feature, bug fix, tests, docs, etc.), ALWAYS: (1) offer the user the next step by prompting via `ask_user`; repeat this feedback loop until the user explicitly indicates they are done.
<!-- /GSD Configuration -->
