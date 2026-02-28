#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-data-engineer}"
AWS_REGION="${AWS_REGION:-us-east-1}"
STACK_NAME="${STACK_NAME:-ecs-blue-green-demo-stack}"
TEMPLATE_FILE="${TEMPLATE_FILE:-deploy-blue-green.yml}"

IMAGE_URI_BLUE="${IMAGE_URI_BLUE:-894064921954.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest}"
IMAGE_URI_GREEN="${IMAGE_URI_GREEN:-894064921954.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest}"
ACTIVE_COLOR="${ACTIVE_COLOR:-blue}"

CONTAINER_PORT="${CONTAINER_PORT:-8000}"
DESIRED_COUNT_BLUE="${DESIRED_COUNT_BLUE:-1}"
DESIRED_COUNT_GREEN="${DESIRED_COUNT_GREEN:-1}"
TASK_CPU="${TASK_CPU:-256}"
TASK_MEMORY="${TASK_MEMORY:-512}"

usage() {
  cat <<USAGE
Uso: ./deploy.sh <deploy|switch|status|delete|help> [args]

Comandos:
  deploy                 Crea/actualiza stack (default trafico en blue)
  switch <blue|green>    Cambia 100% del trafico al color indicado
  status                 Muestra ALB y color activo
  delete                 Borra el stack

Variables obligatorias:
  IMAGE_URI_BLUE         URI ECR de version blue
  IMAGE_URI_GREEN        URI ECR de version green
USAGE
}

require_template() {
  [[ -f "${TEMPLATE_FILE}" ]] || { echo "No existe ${TEMPLATE_FILE}" >&2; exit 1; }
}

require_images() {
  [[ -n "${IMAGE_URI_BLUE}" ]] || { echo "Falta IMAGE_URI_BLUE" >&2; exit 1; }
  [[ -n "${IMAGE_URI_GREEN}" ]] || { echo "Falta IMAGE_URI_GREEN" >&2; exit 1; }
}

validate_color() {
  local color="$1"
  [[ "${color}" == "blue" || "${color}" == "green" ]] || { echo "Color invalido: ${color}" >&2; exit 1; }
}

cfn_deploy() {
  local active_color="$1"
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation deploy \
    --stack-name "${STACK_NAME}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --template-file "${TEMPLATE_FILE}" \
    --parameter-overrides \
      ImageURIBlue="${IMAGE_URI_BLUE}" \
      ImageURIGreen="${IMAGE_URI_GREEN}" \
      ActiveColor="${active_color}" \
      ContainerPort="${CONTAINER_PORT}" \
      DesiredCountBlue="${DESIRED_COUNT_BLUE}" \
      DesiredCountGreen="${DESIRED_COUNT_GREEN}" \
      TaskCpu="${TASK_CPU}" \
      TaskMemory="${TASK_MEMORY}" \
    --no-fail-on-empty-changeset
}

status() {
  local alb_dns active_color
  alb_dns="$(aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query "Stacks[0].Outputs[?OutputKey=='ALBDNS'].OutputValue" \
    --output text)"

  active_color="$(aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query "Stacks[0].Outputs[?OutputKey=='ActiveColorOutput'].OutputValue" \
    --output text)"

  echo "ALB DNS: ${alb_dns}"
  echo "Color activo: ${active_color}"
}

delete_stack() {
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation delete-stack --stack-name "${STACK_NAME}"
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation wait stack-delete-complete --stack-name "${STACK_NAME}"
  echo "Stack eliminado: ${STACK_NAME}"
}

main() {
  require_template
  case "${1:-}" in
    deploy)
      require_images
      validate_color "${ACTIVE_COLOR}"
      cfn_deploy "${ACTIVE_COLOR}"
      status
      ;;
    switch)
      require_images
      [[ $# -eq 2 ]] || { echo "Uso: ./deploy.sh switch <blue|green>" >&2; exit 1; }
      validate_color "$2"
      cfn_deploy "$2"
      status
      ;;
    status)
      status
      ;;
    delete)
      delete_stack
      ;;
    help|-h|--help|"")
      usage
      ;;
    *)
      echo "Comando desconocido: $1" >&2
      usage
      exit 2
      ;;
  esac
}

main "$@"
