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

output "start_ingestion_job_command" {
  description = "AWS CLI command to run after `terraform apply` (or whenever docs/knowledge_base/*.md changes) to sync new content into the vector index"
  value       = "aws bedrock-agent start-ingestion-job --knowledge-base-id ${aws_bedrockagent_knowledge_base.sewalink.id} --data-source-id ${aws_bedrockagent_data_source.sewalink_docs.data_source_id} --region ${var.aws_region}"
}
