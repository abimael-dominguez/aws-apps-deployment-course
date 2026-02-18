#!/usr/bin/env bash
set -euo pipefail

# You can override any of these by exporting env vars before running the script.
AWS_PROFILE="${AWS_PROFILE:-data-engineer}"
AWS_REGION="${AWS_REGION:-us-east-1}"

TEMPLATE_FILE="${TEMPLATE_FILE:-ec2-ssh.yml}"
STACK_NAME="${STACK_NAME:-ec2-ssh-stack}"

# AMI ID (parameter in ec2-ssh.yml)
AMI_ID="${AMI_ID:-ami-0c1fe732b5494dc14}"  # Amazon Linux 2023 (kernel 6.1) (us-east-1)
# Alternative example: Ubuntu 24.04 (us-east-1) ami-0b6c6ebed2801a5cb (SSH user: ubuntu)

# REQUIRED: existing EC2 KeyPair name in the chosen region
KEY_NAME="${KEY_NAME:-key-pair-ubuntu-server-tecgurus-001}"

# Security: prefer your public IP /32 instead of 0.0.0.0/0
ALLOWED_CIDR="${ALLOWED_CIDR:-0.0.0.0/0}"

INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
AVAILABILITY_ZONE="${AVAILABILITY_ZONE:-${AWS_REGION}a}"
VPC_CIDR="${VPC_CIDR:-10.0.0.0/16}"
PUBLIC_SUBNET_CIDR="${PUBLIC_SUBNET_CIDR:-10.0.1.0/24}"

usage() {
	cat <<EOF
Usage: ./ec2-ssh.sh <deploy|delete|outputs|help>

Required env vars:
	KEY_NAME        Existing EC2 KeyPair name (region: \$AWS_REGION)

Optional env vars:
	AWS_PROFILE     AWS CLI profile (default: data-engineer)
	AWS_REGION      AWS region (default: us-east-1)
	STACK_NAME      CloudFormation stack name (default: ec2-ssh-stack)
	AMI_ID          AMI ID to use (default: ami-0c1fe732b5494dc14)
	ALLOWED_CIDR    CIDR for SSH ingress (default: 0.0.0.0/0)
	INSTANCE_TYPE   t3.micro (default: t3.micro)
	AVAILABILITY_ZONE Availability Zone (default: \\${AWS_REGION}a)
	VPC_CIDR        VPC CIDR (default: 10.0.0.0/16)
	PUBLIC_SUBNET_CIDR Public subnet CIDR (default: 10.0.1.0/24)

Examples:
	export KEY_NAME="my-keypair"
	export ALLOWED_CIDR="203.0.113.10/32"
	./ec2-ssh.sh deploy

	./ec2-ssh.sh outputs
	./ec2-ssh.sh delete
EOF
}

require_file() {
	local path="$1"
	[[ -f "${path}" ]] || { echo "ERROR: file not found: ${path}" >&2; exit 1; }
}

require_key_name() {
	if [[ -z "${KEY_NAME}" ]]; then
		echo "ERROR: KEY_NAME is required (must be an existing EC2 KeyPair in region ${AWS_REGION})." >&2
		echo "Hint: export KEY_NAME=\"my-keypair\"" >&2
		exit 1
	fi
}

describe_outputs() {
	aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation describe-stacks \
		--stack-name "${STACK_NAME}" \
		--query 'Stacks[0].Outputs' \
		--output table
}

deploy_stack() {
	require_file "${TEMPLATE_FILE}"
	require_key_name

	echo "Deploy stack: ${STACK_NAME} (profile=${AWS_PROFILE}, region=${AWS_REGION})"
	aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation deploy \
		--stack-name "${STACK_NAME}" \
		--template-file "${TEMPLATE_FILE}" \
		--parameter-overrides \
			AmiId="${AMI_ID}" \
			KeyName="${KEY_NAME}" \
			AllowedCidr="${ALLOWED_CIDR}" \
			InstanceType="${INSTANCE_TYPE}" \
			AvailabilityZone="${AVAILABILITY_ZONE}" \
			VpcCidr="${VPC_CIDR}" \
			PublicSubnetCidr="${PUBLIC_SUBNET_CIDR}" \
		--no-fail-on-empty-changeset

	echo "Outputs:"
	describe_outputs

	local public_dns
	public_dns=$(aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" cloudformation describe-stacks \
		--stack-name "${STACK_NAME}" \
		--query "Stacks[0].Outputs[?OutputKey=='PublicDnsName'].OutputValue" \
		--output text)

	if [[ -n "${public_dns}" && "${public_dns}" != "None" ]]; then
		echo
		echo "SSH (replace with your private key path):"
		echo "  ssh -i <path-to-private-key.pem> <ssh-user>@${public_dns}"
	fi
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
		outputs) describe_outputs ;;
		delete) delete_stack ;;
		help|-h|--help|"") usage ;;
		*) echo "ERROR: unknown command: ${1}" >&2; usage; exit 2 ;;
	esac
}

main "$@"
