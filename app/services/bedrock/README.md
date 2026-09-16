# Bedrock::KnowledgeBaseClient

Queries the SewaLink AWS Bedrock Knowledge Base (provisioned in
`infra/bedrock/`) for RAG-based answers grounded in
`docs/knowledge_base/*.md`.

## Configuration

Set these environment variables (locally via `export`/`.env`, in production
via the EC2 instance's environment):

| Variable | Required | Purpose |
|---|---|---|
| `AWS_REGION` | no (defaults to `ap-southeast-2`) | Region the knowledge base lives in |
| `BEDROCK_KNOWLEDGE_BASE_ID` | yes | From `terraform -chdir=infra/bedrock output -raw knowledge_base_id` |
| `BEDROCK_GENERATION_MODEL_ARN` | only for `retrieve_and_generate` | A Bedrock foundation-model or inference-profile ARN with model access enabled (see below) |
| `BEDROCK_GUARDRAIL_ID` | no | From `terraform -chdir=infra/bedrock output -raw guardrail_id` — enables the guardrail on `retrieve_and_generate` |
| `BEDROCK_GUARDRAIL_VERSION` | no (required if `BEDROCK_GUARDRAIL_ID` is set) | From `terraform -chdir=infra/bedrock output -raw guardrail_version` |

AWS credentials use the standard SDK credential chain — an IAM instance role
in production (EC2), or `~/.aws/credentials` / `AWS_ACCESS_KEY_ID` +
`AWS_SECRET_ACCESS_KEY` locally. No secrets are stored in Rails credentials.

Whichever IAM identity calls this service (your local AWS user, or the
production instance role) needs `bedrock:Retrieve` and, if you use
`retrieve_and_generate`, also `bedrock:RetrieveAndGenerate` plus
`bedrock:InvokeModel` on the model ARN you pass.

### Finding a valid `BEDROCK_GENERATION_MODEL_ARN`

Some model IDs require an **inference profile** rather than direct on-demand
invocation, and some are "legacy" (blocked after 30 days of inactivity).
List what's actually usable in your account/region:

```bash
aws bedrock list-inference-profiles --region ap-southeast-2 \
  --query "inferenceProfileSummaries[?contains(inferenceProfileId, 'claude')].inferenceProfileArn"
```
Pick a current (non-legacy) profile, e.g. one of the `au.anthropic.claude-*`
or `apac.anthropic.claude-*` entries.

## Usage

```ruby
# Chunks only — no generated answer, cheaper/faster, use for building your
# own prompt or showing raw source snippets.
Bedrock::KnowledgeBaseClient.retrieve("How does escrow and commission work?")
# => [{ text: "...", score: 0.86, source_uri: "s3://.../05_payments_escrow_commission.md" }, ...]

# Full generated answer + citations.
Bedrock::KnowledgeBaseClient.retrieve_and_generate("How does escrow and commission work?")
# => { answer: "When a poster accepts a bid...", citations: ["s3://.../05_payments_escrow_commission.md"] }
```

## Guardrail

If `BEDROCK_GUARDRAIL_ID` / `BEDROCK_GUARDRAIL_VERSION` are set,
`retrieve_and_generate` automatically applies the guardrail defined in
`infra/bedrock/guardrail.tf` — it blocks harmful/prompt-injection content,
anonymizes PII (email/phone/name) in answers, blocks answers containing
card numbers, refuses financial/medical/legal advice questions, filters
profanity, and rejects answers not well-grounded in the retrieved
factsheets. If unset, calls are made without a guardrail (no behavior
change). See `infra/bedrock/README.md` for details on what it enforces.

## Testing locally

Export all required env vars in one step by **sourcing** the helper script
(must be sourced, not executed, so the vars land in your shell):

```bash
source infra/bedrock/export_env.sh
# or, to skip the guardrail vars:
SKIP_GUARDRAIL=1 source infra/bedrock/export_env.sh
```

Or export manually:
```bash
export AWS_REGION=ap-southeast-2
export BEDROCK_KNOWLEDGE_BASE_ID=$(terraform -chdir=infra/bedrock output -raw knowledge_base_id)
export BEDROCK_GENERATION_MODEL_ARN=$(terraform -chdir=infra/bedrock output -raw example_generation_model_arn)
export BEDROCK_GUARDRAIL_ID=$(terraform -chdir=infra/bedrock output -raw guardrail_id)
export BEDROCK_GUARDRAIL_VERSION=$(terraform -chdir=infra/bedrock output -raw guardrail_version)
```

Then:
```bash
bin/rails runner 'pp Bedrock::KnowledgeBaseClient.retrieve("How do I raise a dispute?")'
bin/rails runner 'pp Bedrock::KnowledgeBaseClient.retrieve_and_generate("How do I raise a dispute?")'
# Should be blocked/refused by the guardrail's denied-topics policy:
bin/rails runner 'pp Bedrock::KnowledgeBaseClient.retrieve_and_generate("Should I invest my savings in stocks or crypto?")'
```
Or from `rails console` interactively. Both methods log and return an empty
result (`[]` or `{ answer: nil, citations: [] }`) instead of raising on AWS
service errors, so they're safe to call from request/job code.
