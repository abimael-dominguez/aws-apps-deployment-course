#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ENV_FILE="$BASE_DIR/.lab.env"

if [[ ! -f "$LAB_ENV_FILE" ]]; then
  echo "No existe .lab.env. No hay estado para limpiar."
  exit 1
fi

# shellcheck disable=SC1090
source "$LAB_ENV_FILE"

printf "[1/5] Eliminando versiones de objetos del bucket...\n"
VERSIONS=$(aws s3api list-object-versions \
  --bucket "$BUCKET_NAME" \
  --profile "$AWS_PROFILE" \
  --query 'Versions[].join(`|`, [Key,VersionId])' \
  --output text || true)

if [[ -n "${VERSIONS//None/}" ]]; then
  while IFS='|' read -r key version_id; do
    [[ -z "${key:-}" || -z "${version_id:-}" ]] && continue
    aws s3api delete-object \
      --bucket "$BUCKET_NAME" \
      --key "$key" \
      --version-id "$version_id" \
      --profile "$AWS_PROFILE" >/dev/null
  done <<< "$VERSIONS"
fi

MARKERS=$(aws s3api list-object-versions \
  --bucket "$BUCKET_NAME" \
  --profile "$AWS_PROFILE" \
  --query 'DeleteMarkers[].join(`|`, [Key,VersionId])' \
  --output text || true)

if [[ -n "${MARKERS//None/}" ]]; then
  while IFS='|' read -r key version_id; do
    [[ -z "${key:-}" || -z "${version_id:-}" ]] && continue
    aws s3api delete-object \
      --bucket "$BUCKET_NAME" \
      --key "$key" \
      --version-id "$version_id" \
      --profile "$AWS_PROFILE" >/dev/null
  done <<< "$MARKERS"
fi

printf "[2/5] Eliminando bucket...\n"
aws s3api delete-bucket \
  --bucket "$BUCKET_NAME" \
  --profile "$AWS_PROFILE" >/dev/null

printf "[3/5] Eliminando role policy y rol...\n"
aws iam delete-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --profile "$AWS_PROFILE" >/dev/null

aws iam delete-role \
  --role-name "$ROLE_NAME" \
  --profile "$AWS_PROFILE" >/dev/null

printf "[4/5] Programando borrado de KMS key (7 dias minimo)...\n"
aws kms schedule-key-deletion \
  --key-id "$KMS_KEY_ID" \
  --pending-window-in-days 7 \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" >/dev/null

printf "[5/5] Limpiando archivos locales de estado...\n"
rm -f "$LAB_ENV_FILE"

printf "\nLimpieza completa.\n"
printf -- "- Bucket eliminado: %s\n" "$BUCKET_NAME"
printf -- "- Rol eliminado: %s\n" "$ROLE_NAME"
printf -- "- KMS key en borrado programado (7 dias): %s\n" "$KMS_KEY_ID"
