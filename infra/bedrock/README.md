# SewaLink Bedrock Knowledge Base — Terraform

Provisions an **AWS Bedrock Knowledge Base** seeded with the Markdown
factsheets in `docs/knowledge_base/`, so a Retrieval-Augmented Generation
(RAG) assistant can answer poster/tasker/admin questions about how SewaLink
works.

This is a separate, self-contained Terraform stack (its own state) from
`infra/` (the EC2 app deployment) — it can be applied, destroyed, or
recreated independently.

## What it creates

| Resource | Purpose |
|---|---|
| `aws_s3_bucket.kb_docs` | Stores the Markdown factsheets (the knowledge base's data source) |
| `aws_s3_object.kb_docs` | Uploads every `*.md` file from `docs/knowledge_base/` automatically |
| `aws_s3vectors_vector_bucket.kb` + `aws_s3vectors_index.kb` | Cost-effective vector store for embeddings (Amazon S3 Vectors) |
| `aws_iam_role.kb` + policy | Least-privilege role Bedrock assumes to embed documents and query vectors |
| `aws_bedrockagent_knowledge_base.sewalink` | The knowledge base itself (Titan Text Embeddings V2, vector type) |
| `aws_bedrockagent_data_source.sewalink_docs` | Connects the S3 bucket to the knowledge base, with fixed-size chunking |
| `aws_bedrock_guardrail.sewalink` | Content-safety guardrail: blocks harmful content/prompt injection, redacts PII, denies off-topic advice (financial/medical/legal), filters profanity, and rejects ungrounded/irrelevant generated answers |
| `aws_bedrock_guardrail_version.sewalink` | Publishes a stable (non-`DRAFT`) guardrail version for runtime use |

**Why S3 Vectors instead of OpenSearch Serverless?** It's purpose-built for
this use case — much cheaper for a small, infrequently-queried document set,
with no cluster/collection to manage, at the cost of sub-second (not
millisecond) query latency and semantic-only (no hybrid) search. That's a
good trade-off for a support/FAQ knowledge base at SewaLink's current scale.

## Prerequisites

- Terraform >= 1.5, AWS provider `~> 6.0` (first version with S3 Vectors +
  Bedrock Knowledge Base resources).
- AWS credentials with permission to manage S3, S3 Vectors, IAM, and Bedrock
  (e.g. via `aws configure` or exported `AWS_PROFILE`).
- Model access to `amazon.titan-embed-text-v2:0` enabled in the target
  region's Bedrock console (**Model access** page) — Terraform cannot grant
  this, it must be enabled once per account/region.
- The target region must support both Bedrock Knowledge Bases and Amazon S3
  Vectors (default here is `ap-southeast-2`, matching `infra/`).

## Usage

```bash
cd infra/bedrock
terraform init
terraform plan
terraform apply
```

All variables have sensible defaults (see `variables.tf`) — no
`terraform.tfvars` is required for a first deploy. Override `project_name`,
`aws_region`, or embedding/chunking settings if needed.

## Keeping the knowledge base in sync

`terraform apply` uploads any new/changed `.md` files to S3, but Bedrock only
re-embeds content when an **ingestion job** runs. After editing
`docs/knowledge_base/*.md` and re-applying, trigger a sync:

```bash
terraform output -raw start_ingestion_job_command | bash
```

Or manually:
```bash
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id "$(terraform output -raw knowledge_base_id)" \
  --data-source-id "$(terraform output -raw data_source_id)" \
  --region ap-southeast-2
```

## Querying from the app

Query the knowledge base from Rails via
`app/services/bedrock/knowledge_base_client.rb` (see
`app/services/bedrock/README.md` for configuration and usage), which wraps
the `bedrock-agent-runtime` `Retrieve` / `RetrieveAndGenerate` APIs using
the `aws-sdk-bedrockagentruntime` gem — set `BEDROCK_KNOWLEDGE_BASE_ID` to
this stack's `knowledge_base_id` output.

## Guardrail

`aws_bedrock_guardrail.sewalink` is applied only to `RetrieveAndGenerate`
calls (generation), not to plain `Retrieve` (raw chunk search) — it has no
effect unless the caller passes a `guardrail_configuration`. It enforces:

- **Content filters**: blocks hate/insults/sexual/violence/misconduct content
  and prompt-injection attempts, on both input and output.
- **Sensitive information**: anonymizes email/phone/name in generated
  answers; blocks answers containing a credit/debit card number outright.
- **Denied topics**: refuses to give financial, medical, or legal advice —
  SewaLink is a task marketplace, not an advisory service.
- **Word filters**: blocks the managed profanity word list.
- **Contextual grounding**: rejects generated answers that aren't well
  supported by the retrieved factsheets (`GROUNDING`) or that drift from the
  user's question (`RELEVANCE`), each with a configurable threshold
  (`guardrail_grounding_threshold` / `guardrail_relevance_threshold`, default
  `0.75`).

To use it from the Rails client, export the outputs below:

```bash
export BEDROCK_GUARDRAIL_ID=$(terraform -chdir=infra/bedrock output -raw guardrail_id)
export BEDROCK_GUARDRAIL_VERSION=$(terraform -chdir=infra/bedrock output -raw guardrail_version)
```

Or simply `source infra/bedrock/export_env.sh`, which exports this along
with every other env var the client needs (see
`app/services/bedrock/README.md`).

`Bedrock::KnowledgeBaseClient.retrieve_and_generate` picks these up
automatically (see `app/services/bedrock/README.md`) — if unset, calls are
made without a guardrail.

## Outputs

Run `terraform output` after apply to see: `knowledge_base_id`,
`knowledge_base_arn`, `data_source_id`, `docs_bucket_name`,
`vector_bucket_name`, `vector_index_name`, `kb_role_arn`,
`start_ingestion_job_command`, `guardrail_id`, `guardrail_arn`, and
`guardrail_version`.

## Cost notes

- S3 Vectors and the S3 docs bucket are pay-per-use with no idle
  infrastructure cost (unlike OpenSearch Serverless, which bills for
  provisioned OCUs even when idle).
- Costs are incurred per ingestion job (embedding calls to Titan) and per
  `Retrieve`/`RetrieveAndGenerate` query at runtime.

## Tearing down

```bash
terraform destroy
```
By default, deleting the knowledge base/data source also deletes the
vectors in the S3 Vectors index (Bedrock's `Delete` data-deletion policy).
