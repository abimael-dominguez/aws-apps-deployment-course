#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-data-engineer}"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-894064921954}"
TEMPLATE_FILE="${TEMPLATE_FILE:-deploy-ecs-fargate-alb-autoscaling.yml}"
STACK_NAME="${STACK_NAME:-ecs-fastapi-autoscaling-stack}"
REPO_NAME="${REPO_NAME:-dev/fastapi-repo}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_PORT="${CONTAINER_PORT:-8000}"
ALLOWED_CIDR="${ALLOWED_CIDR:-0.0.0.0/0}"
TASK_CPU="${TASK_CPU:-256}"
TASK_MEMORY="${TASK_MEMORY:-512}"
MIN_CAPACITY="${MIN_CAPACITY:-2}"
MAX_CAPACITY="${MAX_CAPACITY:-6}"
IMAGE_URI="${IMAGE_URI:-${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}}"
usage() {
  cat <<EOF
Usage: ./deploy.sh <deploy|delete|help>

Env vars (opcionales):
  AWS_PROFILE, AWS_REGION, AWS_ACCOUNT_ID
  TEMPLATE_FILE, STACK_NAME
  REPO_NAME, IMAGE_TAG, IMAGE_URI
  CONTAINER_PORT, ALLOWED_CIDR, TASK_CPU, TASK_MEMORY
  MIN_CAPACITY, MAX_CAPACITY

Ejemplo:
  ./deploy.sh deploy
  MIN_CAPACITY=1 MAX_CAPACITY=4 ./deploy.sh deploy
EOF
}

require_file() {
  local path="$1"
  [[ -f "${path}" ]] || { echo "ERROR: no existe ${path}" >&2; exit 1; }
}

deploy_stack() {
  require_file "${TEMPLATE_FILE}"

  echo "Deploy stack: ${STACK_NAME} (profile=${AWS_PROFILE}, region=${AWS_REGION})"
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation deploy \
    --stack-name "${STACK_NAME}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --template-file "${TEMPLATE_FILE}" \
    --parameter-overrides \
      ImageURI="${IMAGE_URI}" \
      ContainerPort="${CONTAINER_PORT}" \
      AllowedCidr="${ALLOWED_CIDR}" \
      TaskCpu="${TASK_CPU}" \
      TaskMemory="${TASK_MEMORY}" \
      MinCapacity="${MIN_CAPACITY}" \
      MaxCapacity="${MAX_CAPACITY}" \
    --no-fail-on-empty-changeset

  echo "Outputs:"
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query "Stacks[0].Outputs" \
    --output table
}

delete_stack() {
  echo "Delete stack: ${STACK_NAME} (profile=${AWS_PROFILE}, region=${AWS_REGION})"
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation delete-stack --stack-name "${STACK_NAME}"
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation wait stack-delete-complete --stack-name "${STACK_NAME}"
  echo "Deleted."
}

main() {
  case "${1:-}" in
    deploy) deploy_stack ;;
    delete) delete_stack ;;
    help|-h|--help|"") usage ;;
    *) echo "ERROR: comando desconocido: ${1}" >&2; usage; exit 2 ;;
  esac
}

main "$@"
