# SewaLink Knowledge Base (sample) — for AWS Bedrock

This folder contains 10 sample factsheets (Markdown) describing how SewaLink
works (for posters, taskers, and admins), intended as seed content for an AWS
Bedrock Knowledge Base (S3 data source + vector store, e.g. OpenSearch
Serverless) powering a RAG-based support/chat assistant.

**Markdown (`.md`) is the canonical source for RAG ingestion** — it chunks
cleanly (no PDF layout artifacts like headers/footers or column reflow) and
preserves heading/table structure that Bedrock's KB parser and chunker can
use directly. Production-ready PDFs (if needed for human distribution) will
be authored separately and are out of scope for this folder.

## Files
1. `01_platform_overview.md` – What SewaLink is, who uses it
2. `02_poster_guide.md` – Posting and managing a task
3. `03_tasker_guide.md` – Finding, bidding, and completing tasks
4. `04_task_lifecycle.md` – Full task status reference table
5. `05_payments_escrow_commission.md` – Payments, escrow, commission FAQ
6. `06_safety_geofencing.md` – Location check-in policy & safety tips
7. `07_disputes_resolution.md` – Dispute process and outcomes
8. `08_reviews_ratings.md` – Review/rating rules
9. `09_account_security_otp.md` – Login, OTP, account security
10. `10_admin_platform_settings.md` – Admin responsibilities & platform config

These files are static, hand-maintained Markdown — edit them directly (no
generator/build step involved).

## Next steps (Bedrock)
- Upload the `.md` files to an S3 bucket (e.g. `s3://sewalink-kb/factsheets/`).
- Create a Bedrock Knowledge Base pointing at that S3 prefix, with a vector
  store (OpenSearch Serverless or Aurora pgvector) and an embeddings model
  (e.g. Titan Embeddings).
- Sync the data source, then query via `bedrock-agent-runtime` `Retrieve` /
  `RetrieveAndGenerate` APIs from a Rails service (e.g.
  `app/services/bedrock/knowledge_base_client.rb`), following the same
  service-object pattern used by `app/services/payments/` and
  `app/services/gemini/`.
