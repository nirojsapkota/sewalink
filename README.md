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
ENV['GEMINI_API_KEY'] || Rails.application.credentials.gemini_api_key || Rails.application.credentials.dig(:gemini, :api_key)
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

## Gemini Live Chat: Tool Calling

The real-time voice assistant (`app/javascript/controllers/real_time_chat_controller.js`) lets
Gemini invoke server-side "tools" (e.g. `create_task_draft`, `publish_task`, `query_tasks`) mid
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
   against a fixed `case/when` (`create_task_draft`, `publish_task`, `query_tasks`) — a simple
   string-equality whitelist, not dynamic method dispatch (`send`). Unknown names return a
   `404`-style error.
5. **The result flows back to Gemini** as a `functionResponse`, so the model can continue the
   conversation using the tool's output.
