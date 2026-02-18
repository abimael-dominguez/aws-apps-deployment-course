# EC2 SSH (CloudFormation)

This folder contains a minimal IaC setup to deploy an EC2 instance (Free Tier friendly) with SSH access.

It creates:
- A new VPC + public subnet + Internet Gateway + route to the Internet
- A Security Group allowing inbound SSH (`22/tcp`) from a CIDR you choose
- One EC2 instance (default `t3.micro`) using an AMI ID parameter (default: Amazon Linux 2023 (kernel 6.1) in `us-east-1`: `ami-0c1fe732b5494dc14`)

Note: AMI IDs are region-specific. If you deploy in a different region and this AMI is not available, override `AmiId`.

## Prerequisites

- AWS CLI v2 configured
- An AWS CLI profile you will use for all commands (example: `data-engineer`)
- An existing EC2 KeyPair in the target region

Notes about KeyPair:
- Create the key pair first, then deploy.
- If you already deployed, update the stack with the right `KeyName` (this typically replaces the EC2 instance).

## Configure variables

From this directory:

```bash
cd setup-templates/1-ec2-ssh
chmod +x ec2-ssh.sh

export AWS_PROFILE="data-engineer"
export AWS_REGION="us-east-1"

# Optional: AMI ID (region-specific)
export AMI_ID="ami-0c1fe732b5494dc14"  # Amazon Linux 2023 (kernel 6.1) (us-east-1)
# Alternative example: Ubuntu 24.04 (us-east-1) ami-0b6c6ebed2801a5cb (SSH user: ubuntu)

# REQUIRED: must already exist in EC2 > Key pairs (same region)
export KEY_NAME="my-keypair"

# Recommended: your public IP /32 (instead of 0.0.0.0/0)
export ALLOWED_CIDR="203.0.113.10/32"

# Optional but recommended: pin an AZ that supports your instance type
# (Some accounts don't have t3.micro in all us-east-1 AZs, e.g. us-east-1e)
export AVAILABILITY_ZONE="us-east-1a"
```

Why set env vars if the script already has defaults?
- The script uses defaults so it can run without extra flags.
- Exporting lets you override defaults without editing the script (useful for switching accounts/regions).
- You can also pass env vars inline for a single command (no exports needed).

Inline example (single command):

```bash
AWS_PROFILE="data-engineer" \
AWS_REGION="us-east-1" \
KEY_NAME="my-keypair" \
ALLOWED_CIDR="203.0.113.10/32" \
./ec2-ssh.sh deploy
```

Tip to get your public IP:

```bash
curl -s https://checkip.amazonaws.com
```

## Deploy

### Option A: Use the provided script (recommended)

```bash
./ec2-ssh.sh deploy
```

To view outputs again:

```bash
./ec2-ssh.sh outputs
```

### Option B: AWS CLI commands (explicit)

```bash
aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation deploy \
	--stack-name ec2-ssh-stack \
	--template-file ec2-ssh.yml \
	--parameter-overrides \
		AmiId="$AMI_ID" \
		KeyName="$KEY_NAME" \
		AllowedCidr="$ALLOWED_CIDR" \
		AvailabilityZone="$AVAILABILITY_ZONE" \
		InstanceType="t3.micro" \
	--no-fail-on-empty-changeset

aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation describe-stacks \
	--stack-name ec2-ssh-stack \
	--query "Stacks[0].Outputs" \
	--output table
```

## SSH into the instance

Quick one-liner (copy/paste):

```bash
ssh -i ~/.ssh/<your-private-key>.pem <ssh-user>@"$(aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation describe-stacks \
	--stack-name ec2-ssh-stack \
	--query "Stacks[0].Outputs[?OutputKey=='PublicDnsName'].OutputValue" \
	--output text)"
```

1) Get the instance public DNS (from stack outputs):

```bash
PUBLIC_DNS=$(aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation describe-stacks \
	--stack-name ec2-ssh-stack \
	--query "Stacks[0].Outputs[?OutputKey=='PublicDnsName'].OutputValue" \
	--output text)
echo "$PUBLIC_DNS"
```

2) SSH (username depends on the AMI):

- Default (Amazon Linux 2 / AL2023): `ec2-user`
- Ubuntu: `ubuntu`

```bash
# Update the path to your private key .pem file
ssh -i ~/.ssh/<your-private-key>.pem <ssh-user>@"$PUBLIC_DNS"
```

Tip: you can also print the template SSH command from stack outputs:

```bash
aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation describe-stacks \
	--stack-name ec2-ssh-stack \
	--query "Stacks[0].Outputs[?OutputKey=='SshCommand'].OutputValue" \
	--output text
```

### Troubleshooting SSH

First-time connection prompt is normal:

- You may see: `The authenticity of host ... can't be established` and an `ED25519 key fingerprint ...`
- That `ED25519` fingerprint is the *server/host key* for the EC2 instance (not your `.pem` key)
- Type `yes` to add it to `~/.ssh/known_hosts`

Private key permissions (macOS/Linux):

```bash
chmod 400 /path/to/your-key.pem
```

If permissions are too open (e.g. `0644`), SSH will ignore the key and you’ll get `Permission denied (publickey)`.

Confirm you are using the right KeyPair + AMI for the instance:

```bash
INSTANCE_ID=$(aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation describe-stacks \
	--stack-name ec2-ssh-stack \
	--query "Stacks[0].Outputs[?OutputKey=='InstanceId'].OutputValue" \
	--output text)

aws --profile "$AWS_PROFILE" --region "$AWS_REGION" ec2 describe-instances \
	--instance-ids "$INSTANCE_ID" \
	--query "Reservations[0].Instances[0].{KeyName:KeyName,ImageId:ImageId,State:State.Name,PublicDnsName:PublicDnsName}" \
	--output table
```

Identify the AMI OS (to choose the SSH username):

```bash
IMAGE_ID=$(aws --profile "$AWS_PROFILE" --region "$AWS_REGION" ec2 describe-instances \
	--instance-ids "$INSTANCE_ID" \
	--query "Reservations[0].Instances[0].ImageId" \
	--output text)

aws --profile "$AWS_PROFILE" --region "$AWS_REGION" ec2 describe-images \
	--image-ids "$IMAGE_ID" \
	--query "Images[0].{Name:Name,Description:Description,OwnerId:OwnerId}" \
	--output table
```

If you get `Permission denied (publickey)`, confirm:
- You are using the correct `.pem` file for `KEY_NAME`
- File permissions: `chmod 400 ~/.ssh/<your-private-key>.pem`
- Your `ALLOWED_CIDR` includes your current public IP

## Install Docker (on the EC2 instance)

### Amazon Linux 2023 (default AMI) — user `ec2-user`

```bash
sudo dnf -y update
sudo dnf -y install docker
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user
newgrp docker

docker --version
docker run --rm hello-world


# Git
sudo dnf -y install git
git --version
```

Docker Compose on Amazon Linux 2023:

- Some AL2023 repos don’t include `docker-compose-plugin`. If you need Compose, try:

```bash
sudo dnf -y search docker-compose
sudo dnf -y install docker-compose || true

# If installed, v1 is typically:
docker-compose --version
```

### Ubuntu (alternative AMI) — user `ubuntu`

```bash
sudo apt-get update -y
sudo apt-get install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker

sudo usermod -aG docker ubuntu

# log out and SSH back in, or:
newgrp docker

docker --version
docker compose version
docker run --rm hello-world

# Git
sudo apt-get install -y git
git --version
```

## Delete

### Script

```bash
./ec2-ssh.sh delete
```

### AWS CLI

```bash
aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation delete-stack --stack-name ec2-ssh-stack
aws --profile "$AWS_PROFILE" --region "$AWS_REGION" cloudformation wait stack-delete-complete --stack-name ec2-ssh-stack
```
