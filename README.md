# Project Setup Instructions

This guide will help you set up the development environment and configure AWS credentials.

## Prerequisites

- Python 3.8 or higher
- Docker installed
- pip (Python package installer)
- AWS account with access credentials

## Setting Up the Development Environment

### 1. Create a Virtual Environment

For Windows:
```bash
# Create a virtual environment
python -m venv .venv

# Activate the virtual environment
.\.venv\Scripts\activate
```

For macOS/Linux:
```bash
# Create a virtual environment
python -m venv .venv

# Activate the virtual environment
source .venv/bin/activate
```

### 2. Install Dependencies
Once the virtual environment is activated, install the required packages:

```bash
python -m pip install --upgrade pip
python -m pip install -r ./requirements.txt
```

### 3. Create requirements.txt

If you don't have a requirements.txt file yet, create one with these minimum dependencies:

```bash
# Set of dependencies for pip.
# Note: use python 3.8

pandas==1.3.5
requests==2.28.2
httpx==0.24.0
pydantic==1.10.7
boto3==1.28.44
botocore==1.31.44
fastapi==0.103.1
python-dotenv==1.0.0
uvicorn==0.23.2
awscli==1.29.44
```

## AWS Configuration
### 1. Install AWS CLI
The AWS CLI will be installed automatically through the requirements.txt file. However, if you need to install it separately:
```bash
python -m pip install awscli
```
### 2. Configure AWS Credentials
Run the following command and follow the prompts to enter your AWS credentials:
```bash
aws configure
```
You will need to provide:

- AWS Access Key ID
- AWS Secret Access Key
- Default region name (e.g., us-east-1)
- Default output format (json recommended)

### 3. Verify AWS Configuration
To verify your AWS credentials are properly configured:
```bash
aws sts get-caller-identity
```
This should return your AWS account information if configured correctly.

## Environment Variables (optional)
Create a .env file in your project root directory:

```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_DEFAULT_REGION=your_region
```

Never commit your AWS credentials or .env file to version control

Add .env to your .gitignore file

Regularly rotate your AWS access keys

Follow the principle of least privilege when assigning IAM permissions

## Running the Application
After setting up the environment and configuring AWS credentials, you can run the application:
```bash
uvicorn retail_store_api:app --reload
```

Check that you hace access to the aws resourses according to your user.