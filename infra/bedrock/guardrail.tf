# Bedrock Guardrail applied to generation calls against the knowledge base
# (see app/services/bedrock/knowledge_base_client.rb) — filters harmful
# content, redacts PII, blocks off-topic requests (e.g. financial/medical/
# legal advice, which SewaLink is not qualified to give), and enforces that
# generated answers stay grounded in the retrieved factsheets instead of
# hallucinating.

resource "aws_bedrock_guardrail" "sewalink" {
  name        = "${var.project_name}-kb-guardrail"
  description = "Guardrail for the SewaLink Bedrock Knowledge Base assistant"

  blocked_input_messaging   = var.guardrail_blocked_input_messaging
  blocked_outputs_messaging = var.guardrail_blocked_outputs_messaging

  # Blocks harmful content categories in both the user's question and the
  # generated answer. PROMPT_ATTACK only applies to input (jailbreak/prompt
  # injection attempts), so its output_strength must stay NONE.
  content_policy_config {
    filters_config {
      type            = "HATE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "INSULTS"
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
    }
    filters_config {
      type            = "SEXUAL"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "VIOLENCE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "MISCONDUCT"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "PROMPT_ATTACK"
      input_strength  = "HIGH"
      output_strength = "NONE"
    }
  }

  # Redacts common personal data a user might paste into a question, since
  # this assistant should only need general product/policy information, not
  # anyone's actual phone number, email, or payment details.
  sensitive_information_policy_config {
    pii_entities_config {
      type   = "EMAIL"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PHONE"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "NAME"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "CREDIT_DEBIT_CARD_NUMBER"
      action = "BLOCK"
    }
  }

  # Keeps the assistant scoped to SewaLink product/support topics rather
  # than answering as a general-purpose financial/legal/medical advisor.
  topic_policy_config {
    topics_config {
      name       = "FinancialAdvice"
      type       = "DENY"
      definition = "Requests for personalized investment, tax, loan, or financial planning advice unrelated to using SewaLink's own payment, escrow, or commission features."
      examples = [
        "Should I invest my savings in stocks or crypto?",
        "How can I avoid paying taxes on my income?",
      ]
    }
    topics_config {
      name       = "MedicalOrLegalAdvice"
      type       = "DENY"
      definition = "Requests for professional medical or legal advice unrelated to using the SewaLink platform."
      examples = [
        "What should I do about this injury I got on a task?",
        "Can I sue my landlord?",
      ]
    }
  }

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
  }

  # Prevents hallucinated answers: responses must be grounded in, and
  # relevant to, the chunks actually retrieved from docs/knowledge_base/.
  contextual_grounding_policy_config {
    filters_config {
      type      = "GROUNDING"
      threshold = var.guardrail_grounding_threshold
    }
    filters_config {
      type      = "RELEVANCE"
      threshold = var.guardrail_relevance_threshold
    }
  }
}

# Guardrails must be published to a numbered version to be usable outside
# the mutable DRAFT version — the knowledge base client references this.
resource "aws_bedrock_guardrail_version" "sewalink" {
  guardrail_arn = aws_bedrock_guardrail.sewalink.guardrail_arn
  description   = "Published version used by Bedrock::KnowledgeBaseClient"
}
