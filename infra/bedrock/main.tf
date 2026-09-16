# Provisions an AWS Bedrock Knowledge Base backed by Amazon S3 Vectors, seeded
# from the Markdown factsheets in docs/knowledge_base/. This gives a
# Retrieval-Augmented Generation (RAG) assistant a source of truth to answer
# questions from posters, taskers, and admins about how SewaLink works.
#
# Flow: Markdown docs -> S3 bucket (data source) -> Bedrock Knowledge Base
# ingestion job -> embeddings (Titan Text Embeddings V2) -> S3 Vectors index
# -> queried via the bedrock-agent-runtime Retrieve / RetrieveAndGenerate APIs.

data "aws_caller_identity" "current" {}

# Unique suffix so S3 (globally unique) and vector bucket names don't clash
# across accounts/regions if this stack is deployed more than once.
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  docs_bucket_name    = "${var.project_name}-kb-docs-${random_id.suffix.hex}"
  vector_bucket_name  = "${var.project_name}-kb-vectors-${random_id.suffix.hex}"
  vector_index_name   = "${var.project_name}-kb-index"
  embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}"
}

# ---------------------------------------------------------------------------
# S3 data source: holds the Markdown factsheets Bedrock ingests and chunks.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "kb_docs" {
  bucket = local.docs_bucket_name

  tags = {
    Name = "${var.project_name}-kb-docs"
  }
}

resource "aws_s3_bucket_public_access_block" "kb_docs" {
  bucket = aws_s3_bucket.kb_docs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "kb_docs" {
  bucket = aws_s3_bucket.kb_docs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Uploads every .md factsheet so `terraform apply` keeps the data source in
# sync with docs/knowledge_base/ — no manual `aws s3 cp` step required. A
# knowledge base data source sync (see outputs.tf) picks up changes after.
resource "aws_s3_object" "kb_docs" {
  for_each = fileset(var.knowledge_base_docs_path, "[0-9][0-9]_*.md")

  bucket       = aws_s3_bucket.kb_docs.id
  key          = each.value
  source       = "${var.knowledge_base_docs_path}/${each.value}"
  etag         = filemd5("${var.knowledge_base_docs_path}/${each.value}")
  content_type = "text/markdown"
}

# ---------------------------------------------------------------------------
# S3 Vectors: cost-effective vector store for the knowledge base's embeddings.
# ---------------------------------------------------------------------------

resource "aws_s3vectors_vector_bucket" "kb" {
  vector_bucket_name = local.vector_bucket_name
}

resource "aws_s3vectors_index" "kb" {
  vector_bucket_name = aws_s3vectors_vector_bucket.kb.vector_bucket_name
  index_name         = local.vector_index_name
  data_type          = "float32"
  dimension          = var.embedding_dimensions
  distance_metric    = "cosine"

  metadata_configuration {
    # Bedrock-managed fields must be non-filterable per AWS guidance for
    # knowledge bases backed by S3 Vectors.
    non_filterable_metadata_keys = ["AMAZON_BEDROCK_TEXT", "AMAZON_BEDROCK_METADATA"]
  }
}

# ---------------------------------------------------------------------------
# IAM: least-privilege service role Bedrock assumes to run ingestion/queries.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "kb_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"]
    }
  }
}

resource "aws_iam_role" "kb" {
  name               = "${var.project_name}-bedrock-kb-role"
  assume_role_policy = data.aws_iam_policy_document.kb_trust.json
}

data "aws_iam_policy_document" "kb_permissions" {
  # Allow Bedrock to invoke the embedding model over our documents.
  statement {
    sid       = "InvokeEmbeddingModel"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel"]
    resources = [local.embedding_model_arn]
  }

  # Allow Bedrock to read the source Markdown files from S3.
  statement {
    sid       = "ListDocsBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.kb_docs.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid       = "GetDocsObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.kb_docs.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Allow Bedrock to read/write vectors in the S3 Vectors index.
  statement {
    sid    = "S3VectorsAccess"
    effect = "Allow"
    actions = [
      "s3vectors:PutVectors",
      "s3vectors:GetVectors",
      "s3vectors:DeleteVectors",
      "s3vectors:QueryVectors",
      "s3vectors:GetIndex",
    ]
    resources = [
      "arn:aws:s3vectors:${var.aws_region}:${data.aws_caller_identity.current.account_id}:bucket/${aws_s3vectors_vector_bucket.kb.vector_bucket_name}/index/${aws_s3vectors_index.kb.index_name}"
    ]
  }
}

resource "aws_iam_role_policy" "kb" {
  name   = "${var.project_name}-bedrock-kb-policy"
  role   = aws_iam_role.kb.id
  policy = data.aws_iam_policy_document.kb_permissions.json
}

# ---------------------------------------------------------------------------
# Bedrock Knowledge Base + S3 data source
# ---------------------------------------------------------------------------

resource "aws_bedrockagent_knowledge_base" "sewalink" {
  name        = "${var.project_name}-knowledge-base"
  description = "SewaLink product factsheets (posters, taskers, admins) for RAG-based support answers"
  role_arn    = aws_iam_role.kb.arn

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = local.embedding_model_arn

      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = var.embedding_dimensions
          embedding_data_type = "FLOAT32"
        }
      }
    }
  }

  storage_configuration {
    type = "S3_VECTORS"

    s3_vectors_configuration {
      index_arn = aws_s3vectors_index.kb.index_arn
    }
  }

  depends_on = [aws_iam_role_policy.kb]
}

resource "aws_bedrockagent_data_source" "sewalink_docs" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.sewalink.id
  name              = "${var.project_name}-kb-docs-source"

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = aws_s3_bucket.kb_docs.arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"

      fixed_size_chunking_configuration {
        max_tokens         = var.chunking_max_tokens
        overlap_percentage = var.chunking_overlap_percentage
      }
    }
  }
}
