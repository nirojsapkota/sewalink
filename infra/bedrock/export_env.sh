# Exports the env vars Bedrock::KnowledgeBaseClient needs, sourced from
# this stack's Terraform outputs. Must be *sourced*, not executed, so the
# vars land in your current shell:
#
#   source infra/bedrock/export_env.sh
#   # or from anywhere in the repo:
#   . infra/bedrock/export_env.sh
#
# Optional: skip the guardrail vars with SKIP_GUARDRAIL=1 source ...

if [ "${0}" = "${BASH_SOURCE:-$0}" ] && [ -z "${ZSH_VERSION:-}" ]; then
  echo "export_env.sh must be sourced, not executed: 'source infra/bedrock/export_env.sh'" >&2
  exit 1
fi

_bedrock_tf_dir="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"

export AWS_REGION="$(terraform -chdir="$_bedrock_tf_dir" output -raw aws_region 2>/dev/null || echo ap-southeast-2)"
export BEDROCK_KNOWLEDGE_BASE_ID="$(terraform -chdir="$_bedrock_tf_dir" output -raw knowledge_base_id)"
export BEDROCK_GENERATION_MODEL_ARN="$(terraform -chdir="$_bedrock_tf_dir" output -raw example_generation_model_arn)"

if [ -z "${SKIP_GUARDRAIL:-}" ]; then
  export BEDROCK_GUARDRAIL_ID="$(terraform -chdir="$_bedrock_tf_dir" output -raw guardrail_id)"
  export BEDROCK_GUARDRAIL_VERSION="$(terraform -chdir="$_bedrock_tf_dir" output -raw guardrail_version)"
fi

unset _bedrock_tf_dir

echo "Bedrock env vars exported:"
echo "  AWS_REGION=$AWS_REGION"
echo "  BEDROCK_KNOWLEDGE_BASE_ID=$BEDROCK_KNOWLEDGE_BASE_ID"
echo "  BEDROCK_GENERATION_MODEL_ARN=$BEDROCK_GENERATION_MODEL_ARN"
if [ -z "${SKIP_GUARDRAIL:-}" ]; then
  echo "  BEDROCK_GUARDRAIL_ID=$BEDROCK_GUARDRAIL_ID"
  echo "  BEDROCK_GUARDRAIL_VERSION=$BEDROCK_GUARDRAIL_VERSION"
fi
