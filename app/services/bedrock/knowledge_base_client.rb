# Queries the SewaLink AWS Bedrock Knowledge Base (see infra/bedrock/) for
# RAG-based answers grounded in docs/knowledge_base/*.md. Uses the standard
# AWS SDK credential chain (IAM instance role in production, ~/.aws/credentials
# or AWS_* env vars locally) — no secrets are stored in Rails credentials.
#
# Usage:
#   Bedrock::KnowledgeBaseClient.retrieve("How does escrow work?")
#   Bedrock::KnowledgeBaseClient.retrieve_and_generate("How does escrow work?")
module Bedrock
  class KnowledgeBaseClient
    class ConfigurationError < StandardError; end

    # Returns the top matching chunks (with score + source) for a query,
    # without generating a natural-language answer.
    def self.retrieve(query, max_results: 5)
      new.retrieve(query, max_results: max_results)
    end

    # Returns a generated answer plus citations, grounded in retrieved chunks.
    # `model_arn` must be a Bedrock foundation-model or inference-profile ARN
    # with model access enabled in this account/region (see README). Defaults
    # to BEDROCK_GENERATION_MODEL_ARN so it isn't hardcoded per-account here.
    def self.retrieve_and_generate(query, model_arn: nil, max_results: 5)
      new.retrieve_and_generate(query, model_arn: model_arn, max_results: max_results)
    end

    def initialize
      @region = ENV.fetch("AWS_REGION", "ap-southeast-2")
      @knowledge_base_id = ENV["BEDROCK_KNOWLEDGE_BASE_ID"]
    end

    def retrieve(query, max_results: 5)
      ensure_configured!

      response = client.retrieve(
        knowledge_base_id: @knowledge_base_id,
        retrieval_query: { text: query },
        retrieval_configuration: {
          vector_search_configuration: { number_of_results: max_results }
        }
      )

      response.retrieval_results.map do |result|
        {
          text: result.content.text,
          score: result.score,
          source_uri: result.location&.s3_location&.uri
        }
      end
    rescue Aws::Errors::ServiceError => e
      Rails.logger.error "[Bedrock::KnowledgeBaseClient] retrieve failed: #{e.message}"
      []
    end

    def retrieve_and_generate(query, model_arn: nil, max_results: 5)
      ensure_configured!
      model_arn ||= ENV["BEDROCK_GENERATION_MODEL_ARN"]
      raise ConfigurationError, "No generation model_arn given and BEDROCK_GENERATION_MODEL_ARN " \
        "is not set. Pass model_arn:, or export a Bedrock foundation-model / inference-profile " \
        "ARN with model access enabled (see infra/bedrock/README.md)." if model_arn.blank?

      response = client.retrieve_and_generate(
        input: { text: query },
        retrieve_and_generate_configuration: {
          type: "KNOWLEDGE_BASE",
          knowledge_base_configuration: {
            knowledge_base_id: @knowledge_base_id,
            model_arn: model_arn,
            retrieval_configuration: {
              vector_search_configuration: { number_of_results: max_results }
            }
          }
        }
      )

      {
        answer: response.output.text,
        citations: response.citations.flat_map do |citation|
          citation.retrieved_references.map { |ref| ref.location&.s3_location&.uri }
        end.compact
      }
    rescue Aws::Errors::ServiceError => e
      Rails.logger.error "[Bedrock::KnowledgeBaseClient] retrieve_and_generate failed: #{e.message}"
      { answer: nil, citations: [] }
    end

    private

    def client
      @client ||= Aws::BedrockAgentRuntime::Client.new(region: @region)
    end

    def ensure_configured!
      return if @knowledge_base_id.present?

      raise ConfigurationError, "BEDROCK_KNOWLEDGE_BASE_ID is not set. Run " \
        "`terraform output -raw knowledge_base_id` in infra/bedrock/ and export it."
    end
  end
end
