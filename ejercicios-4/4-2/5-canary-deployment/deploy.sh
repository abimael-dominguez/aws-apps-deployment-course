#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-data-engineer}"
AWS_REGION="${AWS_REGION:-us-east-1}"
STACK_NAME="${STACK_NAME:-ecs-canary-demo-stack}"
TEMPLATE_FILE="${TEMPLATE_FILE:-deploy-canary.yml}"

# Debes definir estas variables para tu cuenta
IMAGE_URI_STABLE="${IMAGE_URI_STABLE:-"894064921954.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest"}"
IMAGE_URI_CANARY="${IMAGE_URI_CANARY:-"894064921954.dkr.ecr.us-east-1.amazonaws.com/dev/fastapi-repo:latest"}"

CONTAINER_PORT="${CONTAINER_PORT:-8000}"
DESIRED_COUNT_STABLE="${DESIRED_COUNT_STABLE:-2}"
DESIRED_COUNT_CANARY="${DESIRED_COUNT_CANARY:-1}"
TASK_CPU="${TASK_CPU:-256}"
TASK_MEMORY="${TASK_MEMORY:-512}"

# Estos pesos se pueden comprobar en el listener del ALB. El peso canary se puede ajustar con set-weights o rollback
STABLE_WEIGHT="${STABLE_WEIGHT:-95}"
CANARY_WEIGHT="${CANARY_WEIGHT:-5}"

usage() {
  cat <<USAGE
Uso: ./deploy.sh <deploy|set-weights|rollback|status|delete|help> [args]

Comandos:
  deploy                    Crea/actualiza stack con pesos actuales (default 95/5)
  set-weights <S> <C>       Actualiza pesos (ej: 75 25). Deben sumar 100.
  rollback                  Atajo a 100/0 (todo al estable)
  status                    Muestra DNS del ALB y pesos configurados
  delete                    Borra el stack

Variables obligatorias:
  IMAGE_URI_STABLE          URI ECR de versión estable
  IMAGE_URI_CANARY          URI ECR de versión canary (puede ser igual para demo)
USAGE
}

require_template() {
  [[ -f "${TEMPLATE_FILE}" ]] || { echo "No existe ${TEMPLATE_FILE}" >&2; exit 1; }
}

require_images() {
  [[ -n "${IMAGE_URI_STABLE}" ]] || { echo "Falta IMAGE_URI_STABLE" >&2; exit 1; }
  [[ -n "${IMAGE_URI_CANARY}" ]] || { echo "Falta IMAGE_URI_CANARY" >&2; exit 1; }
}

validate_weights() {
  local stable="$1"
  local canary="$2"
  local sum=$((stable + canary))
  if [[ "${sum}" -ne 100 ]]; then
    echo "Los pesos deben sumar 100. Recibido: ${stable}+${canary}=${sum}" >&2
    exit 1
  fi
}

cfn_deploy() {
  local stable_weight="$1"
  local canary_weight="$2"

  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation deploy \
    --stack-name "${STACK_NAME}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --template-file "${TEMPLATE_FILE}" \
    --parameter-overrides \
      ImageURIStable="${IMAGE_URI_STABLE}" \
      ImageURICanary="${IMAGE_URI_CANARY}" \
      ContainerPort="${CONTAINER_PORT}" \
      DesiredCountStable="${DESIRED_COUNT_STABLE}" \
      DesiredCountCanary="${DESIRED_COUNT_CANARY}" \
      StableWeight="${stable_weight}" \
      CanaryWeight="${canary_weight}" \
      TaskCpu="${TASK_CPU}" \
      TaskMemory="${TASK_MEMORY}" \
    --no-fail-on-empty-changeset
}

status() {
  local alb_dns listener_arn
  alb_dns="$(aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query "Stacks[0].Outputs[?OutputKey=='ALBDNS'].OutputValue" \
    --output text)"

  listener_arn="$(aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query "Stacks[0].Outputs[?OutputKey=='ListenerArn'].OutputValue" \
    --output text)"

  echo "ALB DNS: ${alb_dns}"
  echo "Pesos configurados (TargetGroups):"
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" elbv2 describe-listeners \
    --listener-arns "${listener_arn}" \
    --query "Listeners[0].DefaultActions[0].ForwardConfig.TargetGroups[*].[TargetGroupArn,Weight]" \
    --output table
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
      validate_weights "${STABLE_WEIGHT}" "${CANARY_WEIGHT}"
      cfn_deploy "${STABLE_WEIGHT}" "${CANARY_WEIGHT}"
      status
      ;;
    set-weights)
      require_images
      [[ $# -eq 3 ]] || { echo "Uso: ./deploy.sh set-weights <stable> <canary>" >&2; exit 1; }
      validate_weights "$2" "$3"
      cfn_deploy "$2" "$3"
      status
      ;;
    rollback)
      require_images
      cfn_deploy 100 0
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
