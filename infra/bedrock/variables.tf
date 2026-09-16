variable "aws_region" {
  description = "AWS region to deploy into. Must support both Amazon Bedrock Knowledge Bases and Amazon S3 Vectors."
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Name prefix used for all resources"
  type        = string
  default     = "sewalink"
}

variable "knowledge_base_docs_path" {
  description = "Local path (relative to this module) to the Markdown factsheets uploaded as the knowledge base's S3 data source"
  type        = string
  default     = "../../docs/knowledge_base"
}

variable "embedding_model_id" {
  description = "Bedrock foundation model id used to generate embeddings. Amazon Titan Text Embeddings V2 is multilingual (incl. Nepali) and cost-effective."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "embedding_dimensions" {
  description = "Vector dimensions produced by the embedding model. Titan Text Embeddings V2 supports 256, 512, or 1024 — 1024 gives the best retrieval quality."
  type        = number
  default     = 1024
}

variable "chunking_max_tokens" {
  description = "Maximum tokens per chunk when Bedrock splits each document for embedding"
  type        = number
  default     = 300
}

variable "chunking_overlap_percentage" {
  description = "Percentage overlap between consecutive chunks, so context isn't lost at chunk boundaries"
  type        = number
  default     = 20
}

variable "guardrail_blocked_input_messaging" {
  description = "Message returned to the user when the guardrail blocks their question"
  type        = string
  default     = "Sorry, I can't help with that request. Please ask a question about using SewaLink."
}

variable "guardrail_blocked_outputs_messaging" {
  description = "Message returned to the user when the guardrail blocks the generated answer"
  type        = string
  default     = "Sorry, I couldn't generate a safe answer to that. Please try rephrasing your question, or contact SewaLink support."
}

variable "guardrail_grounding_threshold" {
  description = "Minimum grounding score (0-1) required for a generated answer to pass — higher values reject answers not well-supported by the retrieved factsheets"
  type        = number
  default     = 0.75
}

variable "guardrail_relevance_threshold" {
  description = "Minimum relevance score (0-1) required for a generated answer to pass — higher values reject answers that drift from the user's actual question"
  type        = number
  default     = 0.75
}
