# PrivateBin on AWS using Terraform

## Overview

This project deploys **PrivateBin S3 (v2.1.1)** on an AWS EC2 instance using Terraform. PrivateBin is a secure, self-hosted pastebin application that stores encrypted notes in Amazon S3.

The infrastructure is provisioned using Infrastructure as Code (IaC), with security best practices, remote Terraform state management, and automated CI checks using GitHub Actions.

## Architecture

The solution consists of:

- **Amazon EC2:** Runs the PrivateBin Docker container on a `t3.micro` instance.
- **Amazon S3 (Notes):** Stores PrivateBin notes with versioning and server-side encryption.
- **Amazon S3 (Access Logs):** Stores S3 server access logs.
- **IAM Role:** Grants EC2 permission to access the notes bucket without storing AWS access keys.
- **AWS Systems Manager (SSM):** Provides secure instance access without SSH.
- **Security Group:** Restricts application access on port 3344 to the configured IP address.
- **Terraform S3 Backend:** Stores Terraform state remotely with encryption and state locking.

## Technology Stack

| Category | Technologies |
|---|---|
| Infrastructure as Code | Terraform |
| Cloud Platform | AWS |
| Compute | Amazon EC2 (t3.micro) |
| Storage | Amazon S3 |
| Containerization | Docker |
| Application | PrivateBin S3 2.1.1 |
| Identity and Access | AWS IAM |
| Instance Management | AWS Systems Manager |
| CI/CD | GitHub Actions |
| Linting | TFLint |
| Security Scanning | Checkov |

## Project Structure

```text
privatebin-terraform/
│
├── modules/
│   └── privatebin/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── conf.php
│
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── .tflint.hcl
├── .gitignore
├── .gitattributes
├── README.md
│
└── .github/
    └── workflows/
        └── ci.yml
```

## Security Implementation

- S3 buckets have public access blocked.
- S3 buckets use AES-256 server-side encryption.
- S3 versioning is enabled to protect stored data.
- IAM roles provide EC2 with least-purpose S3 access without hardcoded credentials.
- Security group ingress is restricted to the configured client IP.
- SSH access is not enabled; administration is performed through SSM Session Manager.
- EC2 uses IMDSv2 with required metadata tokens.
- The root EBS volume is encrypted.
- Terraform state is stored in an encrypted S3 backend with locking enabled.
- S3 server access logging is configured for the notes bucket.

## Deployment

### Prerequisites

- AWS CLI configured with appropriate permissions.
- Terraform installed.
- Docker installed (for local testing).
- An AWS account and an existing Terraform state bucket.

### Steps

**1. Clone the repository**

```bash
git clone https://github.com/saacheesaluja/privatebin-terraform.git
cd privatebin-terraform
```

**2. Initialize Terraform**

```bash
terraform init
```

**3. Configure variables**

Update `allowed_ip` in the Terraform variables or supply it through a `.tfvars` file.

**4. Format and validate**

```bash
terraform fmt -recursive
terraform validate
```

**5. Review the execution plan**

```bash
terraform plan
```

**6. Deploy infrastructure**

```bash
terraform apply
```

Review the plan and approve only the intended changes.

**7. Access the application**

Use the SSM port-forwarding command provided in the Terraform outputs, then open:

```text
http://localhost:3344
```

## CI/CD Pipeline

GitHub Actions automatically executes the following checks on pushes and pull requests targeting the `main` branch:

1. Terraform formatting check using `terraform fmt -check -recursive`.
2. Terraform initialization and validation.
3. TFLint for Terraform linting.
4. Checkov for infrastructure security scanning.

The pipeline validates infrastructure code and identifies potential security misconfigurations before deployment.

## Image Upgrade and Verification

The PrivateBin Docker image was upgraded from **2.0.6 to 2.1.1**.

The upgrade was verified by:

- Pulling the new Docker image.
- Testing the new container independently before switching production traffic.
- Verifying the application returned HTTP 200.
- Confirming successful note creation and retrieval.
- Verifying that the note was stored in the S3 notes bucket.
- Preserving the existing EC2 instance during the upgrade.

## Validation Results

| Check | Result |
|---|---|
| Terraform Format | Passed |
| Terraform Validate | Passed |
| Terraform Plan | No changes |
| TFLint | 0 issues |
| Checkov | 86 passed, 0 failed, 13 skipped |
| GitHub Actions | Successful |

## Key Learning Outcomes

- Provisioning AWS infrastructure using Terraform.
- Creating reusable Terraform modules.
- Managing remote Terraform state and state locking.
- Implementing IAM roles and secure S3 access.
- Deploying containerized applications on EC2.
- Managing instances securely through AWS Systems Manager.
- Implementing infrastructure linting and security scanning.
- Building automated CI pipelines using GitHub Actions.

## Repository

GitHub: https://github.com/saacheesaluja/privatebin-terraform
