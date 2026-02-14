#!/usr/bin/env bash
set -euo pipefail

# Script educativo: despliegue reproducible con CloudFormation
# Template: ./1-ec2-template.yml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/1-ec2-template.yml"

# Variables requeridas (configura con: source .env)
: "${AWS_REGION:?Falta AWS_REGION}"
: "${STACK_NAME:?Falta STACK_NAME}"

# Construir argumentos de AWS CLI
AWS_OPTS=(--region "$AWS_REGION")
[[ -n "${AWS_PROFILE:-}" ]] && AWS_OPTS+=(--profile "$AWS_PROFILE")

case "${1:-}" in
  apply)
    aws cloudformation deploy \
      --stack-name "$STACK_NAME" \
      --template-file "$TEMPLATE" \
      "${AWS_OPTS[@]}"
    echo "✓ Stack desplegado: $STACK_NAME"
    ;;

  status)
    aws cloudformation describe-stacks \
      --stack-name "$STACK_NAME" \
      "${AWS_OPTS[@]}" \
      --query 'Stacks[0].{Nombre:StackName,Estado:StackStatus}' \
      --output table
    ;;

  delete)
    aws cloudformation delete-stack --stack-name "$STACK_NAME" "${AWS_OPTS[@]}"
    echo "Eliminando stack..."
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" "${AWS_OPTS[@]}"
    echo "✓ Stack eliminado: $STACK_NAME"
    ;;

  *)
    echo "Uso: $0 {apply|status|delete}"
    echo ""
    echo "Variables requeridas:"
    echo "  AWS_REGION   Región de AWS (ej: us-east-1)"
    echo "  STACK_NAME   Nombre del stack"
    echo "  AWS_PROFILE  (opcional) Perfil de AWS CLI"
    exit 1
    ;;
esac
