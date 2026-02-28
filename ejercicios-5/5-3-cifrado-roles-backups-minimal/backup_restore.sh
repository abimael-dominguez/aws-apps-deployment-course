#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ENV_FILE="$BASE_DIR/.lab.env"

if [[ ! -f "$LAB_ENV_FILE" ]]; then
  echo "No existe .lab.env. Ejecuta primero ./setup_lab.sh"
  exit 1
fi

# shellcheck disable=SC1090
source "$LAB_ENV_FILE"

cd "$BASE_DIR"
mkdir -p restore

TS=$(date +%Y%m%d-%H%M%S)
BACKUP_KEY="backups/customers-${TS}.json"
RESTORE_FILE="restore/customers-restored-${TS}.json"

printf "[1/3] Subiendo backup cifrado con KMS...\n"
aws s3 cp data/customers.json "s3://$BUCKET_NAME/$BACKUP_KEY" \
  --sse aws:kms \
  --sse-kms-key-id "$KMS_KEY_ID" \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" >/dev/null

SSE=$(aws s3api head-object \
  --bucket "$BUCKET_NAME" \
  --key "$BACKUP_KEY" \
  --profile "$AWS_PROFILE" \
  --query 'ServerSideEncryption' --output text)

printf "[2/3] Restaurando backup...\n"
aws s3 cp "s3://$BUCKET_NAME/$BACKUP_KEY" "$RESTORE_FILE" \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" >/dev/null

printf "[3/3] Validando integridad...\n"
ORIGINAL_HASH=$(sha256sum data/customers.json | awk '{print $1}')
RESTORED_HASH=$(sha256sum "$RESTORE_FILE" | awk '{print $1}')

if [[ "$ORIGINAL_HASH" != "$RESTORED_HASH" ]]; then
  echo "ERROR: hash no coincide"
  echo "original=$ORIGINAL_HASH"
  echo "restore=$RESTORED_HASH"
  exit 1
fi

cat > "$LAB_ENV_FILE" <<EOF_ENV
AWS_PROFILE=$AWS_PROFILE
AWS_REGION=$AWS_REGION
ACCOUNT_ID=$ACCOUNT_ID
LAB_ID=$LAB_ID
BUCKET_NAME=$BUCKET_NAME
KMS_ALIAS=$KMS_ALIAS
KMS_KEY_ID=$KMS_KEY_ID
ROLE_NAME=$ROLE_NAME
POLICY_NAME=$POLICY_NAME
BACKUP_KEY=$BACKUP_KEY
RESTORE_FILE=$RESTORE_FILE
ORIGINAL_HASH=$ORIGINAL_HASH
EOF_ENV

printf "\nOK\n"
printf -- "- SSE: %s\n" "$SSE"
printf -- "- Backup key: %s\n" "$BACKUP_KEY"
printf -- "- Restore file: %s\n" "$RESTORE_FILE"
printf -- "- SHA256: %s\n" "$ORIGINAL_HASH"
printf "\nSiguiente paso:\n"
printf "./cleanup_lab.sh\n"
