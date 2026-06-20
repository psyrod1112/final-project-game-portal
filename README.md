# Game Portal — AWS HA Web Service (Final Project)

A high-availability game portal web service built on AWS using Terraform.

## Architecture

```
Browser
  │
  ├── S3 Static Website (frontend/index.html)
  │     │  fetches API via ALB
  │     ▼
  │   ALB (internet-facing, multi-AZ)
  │     │
  │   ASG: EC2 x2 (Node.js API, port 3000)
  │     │
  │   RDS PostgreSQL (private subnet)
  │
  └── S3 Game Builds Bucket (public download)
```

## AWS Services Used

| Service | Role |
|---------|------|
| S3 | Static frontend hosting + game build downloads |
| EC2 (x2) | Node.js Express API server |
| ALB | Load balancing across 2 AZs |
| ASG | Auto-scaling (min 2, max 4 instances) |
| RDS PostgreSQL | Persistent data (rankings, posts, downloads) |
| CloudWatch | CPU-based scale-out/in alarms |
| Terraform | Infrastructure as Code |

## Features

- **Game Download** — download count tracked in RDS
- **Leaderboard** — submit and view top 10 scores
- **Bulletin Board** — create and read posts

## Quick Start

```bash
# 1. Set AWS credentials (AWS Academy)
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# 2. Set DB password
export TF_VAR_db_password="YourPassword-123"

# 3. Copy tfvars
cp terraform.tfvars.example terraform.tfvars

# 4. Deploy
terraform init
terraform plan -out plan.out
terraform apply plan.out

# 5. Open the app
terraform output frontend_url
```

## HA Verification

```bash
# Check 2 instances are running
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$(terraform output -raw asg_name)" \
  --query 'AutoScalingGroups[0].Instances[*].{ID:InstanceId,AZ:AvailabilityZone,Health:HealthStatus}'

# Terminate one instance — ASG should launch a replacement
aws ec2 terminate-instances --instance-ids <instance-id>
```

## Cleanup

```bash
terraform destroy
```
