# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Configuration

### Gemini API key

The Gemini Live Chat feature (see below) needs a Gemini API key at runtime. It's read via:

```ruby
Rails.application.credentials.gemini_api_key
```

(`app/controllers/gemini/tokens_controller.rb`)

To add it to Rails encrypted credentials (recommended for production):

```bash
EDITOR="vim" bin/rails credentials:edit
```

Then add:

```yaml
gemini_api_key: YOUR_GEMINI_API_KEY
```

This requires `config/master.key` to be present locally (it's gitignored — get it from your
team's secret store, not from git). Alternatively, for local development you can skip
credentials entirely and just set the `GEMINI_API_KEY` environment variable instead.

## Seed Data

Running `bin/rails db:seed` creates demo categories plus three demo accounts (one per role)
so you can log in and exercise each part of the app immediately:

| Role        | Phone        | Password       |
|-------------|--------------|----------------|
| super_admin | 9800000001   | `Password123!` |
| poster      | 9800000002   | `Password123!` |
| tasker      | 9800000003   | `Password123!` |

Login uses phone number, not email (see `User#email_required?`). The password can be
overridden by setting `SEED_USER_PASSWORD` before seeding, e.g.:

```bash
SEED_USER_PASSWORD='MyOwnPassword1!' bin/rails db:seed
```

Seeding is idempotent — re-running it will not create duplicates or reset existing users'
data (it looks users up by phone number first).

## Deployment

Infrastructure lives in `infra/` (Terraform: VPC, EC2 instance, Elastic IP — see that
directory for `terraform apply`/`destroy`). Once the instance is provisioned, ship app code
changes (Dockerfile, Rails code, `docker-compose.yml`, etc.) **without touching
infrastructure** using:

```bash
cd infra
./redeploy.sh
```

This SSHes into the running instance, `git pull`s the latest `main`, and runs
`docker-compose up -d --build` to rebuild and restart the containers. `terraform
plan`/`apply` will correctly show "no changes" for these updates — Terraform only manages
infrastructure, not app deployments.

## TODO

* **Enable SSL/TLS.** The production instance currently serves plain `http://` (no domain,
  no cert — `config.force_ssl = false`). Browsers only expose `navigator.mediaDevices`
  (microphone access) in a secure context (`https://` or `localhost`), so the **voice
  assistant feature is currently broken** on the deployed instance (`Cannot read properties
  of undefined (reading 'getUserMedia')`). Fixing this requires a domain name pointed at the
  instance's IP plus a reverse proxy (e.g. Caddy) for automatic Let's Encrypt certs — Let's
  Encrypt won't issue certs for bare IPs.

## Bedrock Knowledge Base (RAG)

SewaLink's voice assistant and support flows can answer general "how does
this work?" questions (escrow, commission, safety/geofencing, disputes,
reviews, account security, admin settings) by retrieving grounded answers
from an **AWS Bedrock Knowledge Base**, instead of relying on the LLM's own
(unverified) knowledge.

- **Source content**: `docs/knowledge_base/*.md` — 10 hand-maintained
  Markdown factsheets, one per topic area. Edit these directly; there's no
  generator/build step.
- **Infrastructure**: provisioned entirely by Terraform in `infra/bedrock/`
  (a separate, self-contained stack from `infra/`'s EC2 app deployment) —
  an S3 bucket for the docs, an S3 Vectors store for embeddings (Titan Text
  Embeddings V2), the `aws_bedrockagent_knowledge_base` + data source, and
  an `aws_bedrock_guardrail` (blocks harmful/prompt-injection content,
  redacts PII, denies financial/medical/legal advice topics, and rejects
  ungrounded answers). See `infra/bedrock/README.md` for full details,
  setup, and cost notes.
- **Querying from Rails**: `Bedrock::KnowledgeBaseClient` (in
  `app/services/bedrock/`) wraps the `bedrock-agent-runtime`
  `Retrieve`/`RetrieveAndGenerate` APIs. See `app/services/bedrock/README.md`
  for configuration, local testing, and deployment.
- **Local setup**: run `source infra/bedrock/export_env.sh` once (requires
  the `infra/bedrock` Terraform stack to already be applied) — it writes
  the required `AWS_REGION`/`BEDROCK_*` vars into the repo's `.env`, which
  `dotenv-rails` then loads automatically for any `rails
  server`/`console`/`runner`/`bin/dev` command, no manual `export` needed.
  The same `.env` also ships to Docker via `docker-compose.yml`'s `env_file:
  .env` for deployment.
- **Voice assistant integration**: the `search_knowledge_base` Gemini tool
  (see below) queries this knowledge base — gated so it's only invoked for
  genuine help/FAQ-style questions (see "Gemini Live Chat: Tool Calling").

## Gemini Live Chat: Tool Calling

The real-time voice assistant (`app/javascript/controllers/real_time_chat_controller.js`) lets
Gemini invoke server-side "tools" (e.g. `create_task_draft`, `publish_task`, `query_tasks`,
`search_knowledge_base`) mid
conversation. There is no MCP server involved — it's a plain HTTP relay plus a Rails `case/when`
dispatch:

1. **Tool definitions are supplied at session initialization.** `Gemini::TokensController#create`
   (`app/controllers/gemini/tokens_controller.rb`) builds a fresh ephemeral token by calling
   Google's `authTokens:create` endpoint, and reads `response` from that request as the
   provider's HTTP result. In the same action it also maps `Gemini::ToolDefinitions::ALL_TOOLS`
   (`app/services/gemini/tool_definitions.rb`) into the `functionDeclarations` shape Gemini
   expects (`name`, `description`, `parameters`). Both the token/API key and the serialized
   tool list are returned to the browser as JSON from `/gemini/tokens`.
2. **The frontend forwards the tool list to Gemini.** In `real_time_chat_controller.js`,
   `GeminiLiveAPI` stores `tokenData.tools` and sends it inside the WebSocket `setup` message
   (`tools: [{ functionDeclarations: this.tools }]`) when the Live API connection opens. This is
   how Gemini learns which functions it's allowed to call and their expected arguments.
3. **Gemini calls a tool.** When the model decides to invoke one, it sends a `toolCall` message
   over the WebSocket, which `_handleToolCall` receives and relays via `POST
   /gemini/tools/execute` with `{ name, args, call_id }`.
4. **Rails dispatches by name.** `Gemini::ToolsController#execute` matches `params[:name]`
   against a fixed `case/when` (`create_task_draft`, `publish_task`, `query_tasks`,
   `search_knowledge_base`) — a simple
   string-equality whitelist, not dynamic method dispatch (`send`). Unknown names return a
   `404`-style error. `search_knowledge_base` has an extra guard: it's rejected outright
   (no Bedrock call made) unless the query contains a trigger keyword like "help", "faq",
   "guide", or "policy" — see `app/services/gemini/tool_definitions.rb`.
5. **The result flows back to Gemini** as a `functionResponse`, so the model can continue the
   conversation using the tool's output.
