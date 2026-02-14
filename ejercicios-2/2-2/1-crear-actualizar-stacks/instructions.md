# CloudFormation Stack Management

## Console Workflow (Quick Reference)
1. **Create Stack**: Upload template → Name stack → Submit
2. **Update via Change Set**: Stack Actions → Create Change Set → Replace template → Execute
3. **Delete Stack**: Stack Actions → Delete → Verify resources removed

-----
## Exercise 1 - Creating and Updating Stacks (using the Console)

1. Create a Stack (1-ec2-template.md)
    - Use Template -> Upload File -> Name Stack -> Submit
2. Create a Change Set (2-ec2-template.md, 3-ec2-template.md)
    - Stack Actions
    - Create a Change Set
        - Standard Change Set
    - Replace Existing Template
        - Choose File
    - Create Change Set
    - Execute Change Set
    - See what changes were made
3. Delete Stack
    - Stack -> Delete
    - Check all resources were deleted

---

## Exercise 1 - Creating and Updating Stacks (using the AWS CLI)

## CLI Workflow

### Prerequisites
Verify AWS CLI and credentials:
```bash
aws --version
aws configure list-profiles  # List available profiles
```

### Setup Profile & Credentials

**Option 1: Using `aws configure` (recommended)**

Get access keys from IAM Console: **User → Security credentials → Access keys → Create/Download CSV**

```bash
aws configure --profile <PROFILE_NAME>
# Prompts: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

**Option 2: Manual setup (edit files directly)**

Create/edit `~/.aws/config`:
```ini
[profile data-engineer]
region = us-east-1
output = json
```

Create/edit `~/.aws/credentials`:
```ini
[data-engineer]
aws_access_key_id = 
aws_secret_access_key = 
```

**Verify credentials work:**
```bash
export AWS_PROFILE=<PROFILE_NAME>
aws sts get-caller-identity --profile "$AWS_PROFILE"
# Expected: Returns UserId, Account, Arn
```

> **Troubleshooting `InvalidClientTokenId`:**  
> - Access keys: Invalid/expired/deleted → Rotate keys in IAM Console  
> - Never share `~/.aws/credentials` – contains sensitive keys
---

### Environment Setup
```bash
export AWS_PROFILE=<PROFILE_NAME>
export AWS_REGION=us-east-1
export STACK_NAME=tecgurus-ec2-demo
```

**Verify environment:**
```bash
echo "Profile: $AWS_PROFILE | Region: $AWS_REGION | Stack: $STACK_NAME"
```

---

### Step 1: Create Stack

Navigate to the templates directory:
```bash
cd ejercicios-2/2-2/1-crear-actualizar-stacks/
```

Validate and deploy the first template:
```bash
# Validate template syntax (success = JSON output with template metadata)
aws cloudformation validate-template \
  --template-body file://1-ec2-template.yml \
  --region "$AWS_REGION" --profile "$AWS_PROFILE"

# Create stack
aws cloudformation create-stack \
  --stack-name "$STACK_NAME" \
  --template-body file://1-ec2-template.yml \
  --region "$AWS_REGION" --profile "$AWS_PROFILE"

# Wait for completion (~2-5 min)
aws cloudformation wait stack-create-complete \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" --profile "$AWS_PROFILE"
```

**Verify stack created:**
```bash
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" --profile "$AWS_PROFILE" \
  --query 'Stacks[0].[StackName,StackStatus]' --output table
```

---

### Step 2: Update via Change Set

Update the stack using a **change set** (safe preview before applying):
```bash
export CHANGE_SET_NAME=cs-$(date +%Y%m%d-%H%M%S)

# Create change set
aws cloudformation create-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --template-body file://2-ec2-template.yml \
  --region "$AWS_REGION" --profile "$AWS_PROFILE"

# Wait for change set
aws cloudformation wait change-set-create-complete \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --region "$AWS_REGION" --profile "$AWS_PROFILE"
```

**Review changes before applying:**
```bash
aws cloudformation describe-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --region "$AWS_REGION" --profile "$AWS_PROFILE" \
  --query 'Changes[*].[Type,ResourceChange.Action,ResourceChange.LogicalResourceId]' --output table
```

**Execute change set:**
```bash
aws cloudformation execute-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name "$CHANGE_SET_NAME" \
  --region "$AWS_REGION" --profile "$AWS_PROFILE"

aws cloudformation wait stack-update-complete \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" --profile "$AWS_PROFILE"
```

**Verify update:**
```bash
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" --profile "$AWS_PROFILE" \
  --query 'Stacks[0].[StackStatus,LastUpdatedTime]' --output table
```

> **Repeat for `3-ec2-template.yml`:** Re-run the change set commands with `--template-body file://3-ec2-template.yml`

---

### Step 3: Delete Stack

Clean up all resources:
```bash
aws cloudformation delete-stack \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" --profile "$AWS_PROFILE"

aws cloudformation wait stack-delete-complete \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" --profile "$AWS_PROFILE"
```

**Verify deletion:**
```bash
aws cloudformation list-stacks \
  --stack-status-filter DELETE_COMPLETE \
  --region "$AWS_REGION" --profile "$AWS_PROFILE" \
  --query "StackSummaries[?StackName=='$STACK_NAME'].[StackName,StackStatus]" --output table
```

---

## Quick Reference

**List all stacks:**
```bash
aws cloudformation list-stacks --region "$AWS_REGION" --profile "$AWS_PROFILE"
```

**View stack events (troubleshooting):**
```bash
aws cloudformation describe-stack-events \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" --profile "$AWS_PROFILE" --max-items 10
```
