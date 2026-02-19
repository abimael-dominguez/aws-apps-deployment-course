#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="data-engineer"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="894064921954"
TEMPLATE_FILE="deploy-ecs-fargate-alb.yml"
STACK_NAME="ecs-fastapi-stack"
REPO_NAME="fastapi-repo"
IMAGE_TAG="latest"
CONTAINER_PORT="8000"
ALLOWED_CIDR="0.0.0.0/0"
TASK_CPU="256"
TASK_MEMORY="512"
DESIRED_COUNT="2"
# IMAGE_URI="${IMAGE_URI:-${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}}"
IMAGE_URI="894064921954.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest"
usage() {
  cat <<EOF
Usage: ./deploy.sh <deploy|delete|help>

Env vars (opcionales):
  (Este script usa los valores definidos al inicio del archivo)

Ejemplo:
  ./deploy.sh deploy
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
      DesiredCount="${DESIRED_COUNT}" \
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
