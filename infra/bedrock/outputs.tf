output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID — pass to bedrock-agent-runtime Retrieve / RetrieveAndGenerate calls"
  value       = aws_bedrockagent_knowledge_base.sewalink.id
}

output "knowledge_base_arn" {
  value = aws_bedrockagent_knowledge_base.sewalink.arn
}

output "data_source_id" {
  description = "Data source ID — needed to trigger an ingestion (sync) job after uploading new/changed docs"
  value       = aws_bedrockagent_data_source.sewalink_docs.data_source_id
}

output "docs_bucket_name" {
  description = "S3 bucket holding the Markdown factsheets ingested by the knowledge base"
  value       = aws_s3_bucket.kb_docs.bucket
}

output "vector_bucket_name" {
  value = aws_s3vectors_vector_bucket.kb.vector_bucket_name
}

output "vector_index_name" {
  value = aws_s3vectors_index.kb.index_name
}

output "kb_role_arn" {
  description = "IAM role ARN Bedrock assumes to run this knowledge base"
  value       = aws_iam_role.kb.arn
}

output "account_id" {
  description = "AWS account ID this stack was deployed into — use in place of <account_id> when building generation model / inference-profile ARNs"
  value       = data.aws_caller_identity.current.account_id
}

output "example_generation_model_arn" {
  description = "Example inference-profile ARN for BEDROCK_GENERATION_MODEL_ARN. List available profiles with: aws bedrock list-inference-profiles --region <region> --query \"inferenceProfileSummaries[?contains(inferenceProfileId,'claude')].inferenceProfileArn\" (pick a current, non-legacy one)"
  value       = "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/au.anthropic.claude-sonnet-4-5-20250929-v1:0"
}

output "start_ingestion_job_command" {
  description = "AWS CLI command to run after `terraform apply` (or whenever docs/knowledge_base/*.md changes) to sync new content into the vector index"
  value       = "aws bedrock-agent start-ingestion-job --knowledge-base-id ${aws_bedrockagent_knowledge_base.sewalink.id} --data-source-id ${aws_bedrockagent_data_source.sewalink_docs.data_source_id} --region ${var.aws_region}"
}
