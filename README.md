# PostgreSQL Setup with Terraform and Ansible

This repository contains infrastructure as code to:
1. Create a Debian VM with attached external storage for PostgreSQL data
2. Install and configure PostgreSQL
3. Set up cron jobs for maintenance tasks
4. Configure S3 backups for PostgreSQL data

## Project Structure

- `terraform/`: Contains Terraform configuration for VM and storage provisioning
- `ansible/`: Contains Ansible playbooks for PostgreSQL installation and configuration
- `scripts/`: Contains cron job scripts for PostgreSQL maintenance
- `.github/workflows/`: GitHub Actions workflow configuration

## Usage

1. Configure the required variables in `terraform/terraform.tfvars`
2. Run the GitHub Actions workflow to provision infrastructure and configure PostgreSQL
3. Alternatively, run the setup locally using the provided scripts

## Requirements

- Terraform >= 1.0.0
- Ansible >= 2.9.0
- GitHub Actions runner with appropriate permissions

## AWS IAM Permissions

The AWS credentials used in the GitHub Actions workflow (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) require the following IAM permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:ListPolicyVersions",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicyVersion",
        "iam:GetPolicyVersion",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile"
      ],
      "Resource": "*"
    }
  ]
}
```

For production environments, it's recommended to scope these permissions more narrowly to follow the principle of least privilege.

## GitHub Secrets Setup

The following secrets must be configured in your GitHub repository:

1. `AWS_ACCESS_KEY_ID`: Your AWS access key
2. `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
3. `SSH_KEY_NAME`: The name of your EC2 key pair in AWS
4. `SSH_PRIVATE_KEY`: The content of your private key file

To add these secrets:
1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Click "New repository secret" and add each of the required secrets

## Usage

1. Configure the required variables in `terraform/terraform.tfvars`
2. Run the GitHub Actions workflow to provision infrastructure and configure PostgreSQL
3. Alternatively, run the setup locally using the provided scripts
