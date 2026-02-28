#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-data-engineer}"
AWS_REGION="${AWS_REGION:-us-east-1}"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ENV_FILE="$BASE_DIR/.lab.env"

cd "$BASE_DIR"
mkdir -p data restore

ACCOUNT_ID=$(aws sts get-caller-identity \
  --profile "$AWS_PROFILE" \
  --query Account --output text)

LAB_ID="${LAB_ID:-$(date +%Y%m%d%H%M%S)}"
BUCKET_NAME="seg-lab-${ACCOUNT_ID}-${LAB_ID}"
KMS_ALIAS="alias/seguridad-lab-${LAB_ID}"
ROLE_NAME="seguridad-backup-role-${LAB_ID}"
POLICY_NAME="seguridad-backup-policy-${LAB_ID}"

printf "[1/6] Generando datos dummy...\n"
./generate_dummy_data.sh >/dev/null

printf "[2/6] Creando KMS key...\n"
KMS_KEY_ID=$(aws kms create-key \
  --description "KMS key para practica 5.3" \
  --tags TagKey=Project,TagValue=SeguridadLab \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --query KeyMetadata.KeyId --output text)

aws kms create-alias \
  --alias-name "$KMS_ALIAS" \
  --target-key-id "$KMS_KEY_ID" \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION"

printf "[3/6] Creando bucket S3 y versionado...\n"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled \
  --profile "$AWS_PROFILE"

aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "aws:kms",
          "KMSMasterKeyID": "'"$KMS_KEY_ID"'"
        },
        "BucketKeyEnabled": true
      }
    ]
  }' \
  --profile "$AWS_PROFILE"

printf "[4/6] Creando rol IAM...\n"
cat > trust-policy.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON

aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file://trust-policy.json \
  --profile "$AWS_PROFILE" >/dev/null

printf "[5/6] Aplicando policy de minimo privilegio...\n"
cat > permissions-policy.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListSpecificBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::$BUCKET_NAME"]
    },
    {
      "Sid": "RWOnlyBackupPrefix",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": ["arn:aws:s3:::$BUCKET_NAME/backups/*"]
    },
    {
      "Sid": "UseSpecificKmsKey",
      "Effect": "Allow",
      "Action": ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"],
      "Resource": ["arn:aws:kms:$AWS_REGION:$ACCOUNT_ID:key/$KMS_KEY_ID"]
    }
  ]
}
JSON

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document file://permissions-policy.json \
  --profile "$AWS_PROFILE"

printf "[6/6] Guardando estado del laboratorio...\n"
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
EOF_ENV

rm -f trust-policy.json permissions-policy.json

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --profile "$AWS_PROFILE" --query 'Role.Arn' --output text)

printf "\nListo. Recursos creados:\n"
printf -- "- Bucket: %s\n" "$BUCKET_NAME"
printf -- "- KMS Key: %s\n" "$KMS_KEY_ID"
printf -- "- Role ARN: %s\n" "$ROLE_ARN"
printf -- "- Estado: %s\n" "$LAB_ENV_FILE"
printf "\nSiguiente paso:\n"
printf "./backup_restore.sh\n"
