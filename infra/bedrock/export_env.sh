# Writes the env vars Bedrock::KnowledgeBaseClient needs into the repo's
# .env file, sourced from this stack's Terraform outputs.
#
# - Locally (no Docker): `dotenv-rails` (development/test group in Gemfile)
#   auto-loads .env for every `rails server`/`console`/`runner`/`bin/dev`
#   invocation — run this script once, then just use Rails normally.
# - In Docker/deployment: docker-compose.yml's `web` service already loads
#   `env_file: .env`, so the same file doubles as the deployment config —
#   copy .env to wherever `docker-compose up` runs (e.g. the EC2 host).
#
# Just run this once (whenever the values change/the stack is recreated).
#
# Must be *sourced*, not executed, so the vars also land in your current
# shell immediately for local testing:
#
#   source infra/bedrock/export_env.sh
#   # or from anywhere in the repo:
#   . infra/bedrock/export_env.sh
#
# Re-running it is safe/idempotent — it only replaces the BEDROCK_*/
# AWS_REGION lines it manages in .env, leaving any other .env content
# (RAILS_MASTER_KEY, GEMINI_API_KEY, etc) untouched.
#
# Optional: skip the guardrail vars with SKIP_GUARDRAIL=1 source ...

if [ "${0}" = "${BASH_SOURCE:-$0}" ] && [ -z "${ZSH_VERSION:-}" ]; then
  echo "export_env.sh must be sourced, not executed: 'source infra/bedrock/export_env.sh'" >&2
  exit 1
fi

_bedrock_tf_dir="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"
_repo_root="$(cd "$_bedrock_tf_dir/../.." && pwd)"
_env_file="$_repo_root/.env"

export AWS_REGION="$(terraform -chdir="$_bedrock_tf_dir" output -raw aws_region 2>/dev/null || echo ap-southeast-2)"
export BEDROCK_KNOWLEDGE_BASE_ID="$(terraform -chdir="$_bedrock_tf_dir" output -raw knowledge_base_id)"
export BEDROCK_GENERATION_MODEL_ARN="$(terraform -chdir="$_bedrock_tf_dir" output -raw example_generation_model_arn)"

if [ -z "${SKIP_GUARDRAIL:-}" ]; then
  export BEDROCK_GUARDRAIL_ID="$(terraform -chdir="$_bedrock_tf_dir" output -raw guardrail_id)"
  export BEDROCK_GUARDRAIL_VERSION="$(terraform -chdir="$_bedrock_tf_dir" output -raw guardrail_version)"
fi

# Strip any previously-written lines for these keys, then append fresh
# values — preserves unrelated content already in .env.
_managed_keys="AWS_REGION|BEDROCK_KNOWLEDGE_BASE_ID|BEDROCK_GENERATION_MODEL_ARN|BEDROCK_GUARDRAIL_ID|BEDROCK_GUARDRAIL_VERSION"
touch "$_env_file"
grep -Ev "^($_managed_keys)=" "$_env_file" > "$_env_file.tmp" || true
mv "$_env_file.tmp" "$_env_file"

{
  echo "AWS_REGION=$AWS_REGION"
  echo "BEDROCK_KNOWLEDGE_BASE_ID=$BEDROCK_KNOWLEDGE_BASE_ID"
  echo "BEDROCK_GENERATION_MODEL_ARN=$BEDROCK_GENERATION_MODEL_ARN"
  if [ -z "${SKIP_GUARDRAIL:-}" ]; then
    echo "BEDROCK_GUARDRAIL_ID=$BEDROCK_GUARDRAIL_ID"
    echo "BEDROCK_GUARDRAIL_VERSION=$BEDROCK_GUARDRAIL_VERSION"
  fi
} >> "$_env_file"

unset _bedrock_tf_dir _repo_root _managed_keys

echo "Bedrock env vars written to $_env_file and exported to this shell:"
echo "  AWS_REGION=$AWS_REGION"
echo "  BEDROCK_KNOWLEDGE_BASE_ID=$BEDROCK_KNOWLEDGE_BASE_ID"
echo "  BEDROCK_GENERATION_MODEL_ARN=$BEDROCK_GENERATION_MODEL_ARN"
if [ -z "${SKIP_GUARDRAIL:-}" ]; then
  echo "  BEDROCK_GUARDRAIL_ID=$BEDROCK_GUARDRAIL_ID"
  echo "  BEDROCK_GUARDRAIL_VERSION=$BEDROCK_GUARDRAIL_VERSION"
fi

unset _env_file
