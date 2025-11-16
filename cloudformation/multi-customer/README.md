# Multi-Customer Deployment

CloudFormation templates for deploying multiple isolated customer instances with shared infrastructure.

## Deployment Options

### Option 1: Fully Automated (CloudFormation)
Use this README for complete automation via CloudFormation templates.

### Option 2: Learning via GUI (Manual Setup)
**For learning purposes**, see [MANUAL_GUI_SETUP.md](./MANUAL_GUI_SETUP.md) to:
- Deploy VPC, ECR, ECS, IAM, Security Groups via CloudFormation
- Manually create ALB, Task Definitions, Services, etc. via AWS Console GUI
- **Tags**: `multi-customer-gui`, `aws-console`, `manual-setup`, `learning-guide`

---

## Quick Start (Automated)

1. **Create SSL Certificate** → See [Setup SSL Certificate](#setup-ssl-certificate-one-time)
2. **Set Environment Variables** → See [Set Environment Variables](#set-environment-variables)
3. **Deploy Shared Infrastructure** → See [Step 1](#step-1-deploy-shared-infrastructure-once)
4. **Build Docker Images** → See [Step 2](#step-2-build-and-push-docker-images)
5. **Deploy Customers** → See [Step 3](#step-3-deploy-global-customer-freeinterestcalcom) and [Step 4](#step-4-deploy-customer-1-customer1freeinterestcalcom)

## Architecture

- **Shared Infrastructure** (deploy once):
  - VPC with public/private subnets across 2 AZs
  - Security groups
  - ECS Fargate cluster
  - ECR repository
  - Shared Application Load Balancer with HTTPS listener and wildcard SSL

- **Per Customer** (deploy for each):
  - CloudWatch Log Groups (3) - backend-api, backend-worker, frontend
  - Target Groups (2) - backend-api:3001, frontend:3000 (worker has no port)
  - ALB Listener Rules (2) - routes /api/* to backend, / to frontend
  - Task Definitions (3) - backend-api:3001, worker (background), frontend:3000
  - ECS Services (3) - backend-api (with ALB), worker (no ALB), frontend (with ALB)
  - Route 53 DNS Record

## CloudFormation Files

### Shared Infrastructure (Deploy Once - 6 files)

| # | File | Stack Name | Resources | Dependencies |
|---|------|------------|-----------|--------------|
| 1 | `shared-ecr.yaml` | `dev-task-manager-ecr` | ECR Repository | None |
| 2 | `shared-vpc.yaml` | `dev-vpc` | VPC, Subnets, NAT, IGW, Route Tables | None |
| 3 | `shared-security-groups.yaml` | `dev-task-manager-sg` | 4 Security Groups (ALB, Backend API, Worker, Frontend) | VPC |
| 4 | `shared-ecs-cluster.yaml` | `dev-task-manager-cluster` | ECS Cluster, 3 CloudWatch Log Groups | None |
| 5 | `shared-iam.yaml` | `dev-task-manager-iam` | Task Execution Role, Task Role | None |
| 6 | `shared-alb.yaml` | `dev-task-manager-shared-alb` | ALB, HTTP/HTTPS Listeners, Default Target Group | VPC, Security Groups, SSL Cert |

**Total Shared Cost**: ~$81/month

### Per Customer Resources (Deploy for Each - 6 files)

| # | File | Stack Name | Resources | Dependencies |
|---|------|------------|-----------|--------------|
| 1 | `customer-logs.yaml` | `dev-{customer}-logs` | 3 CloudWatch Log Groups | None |
| 2 | `customer-target-groups.yaml` | `dev-{customer}-target-groups` | 2 Target Groups (Backend API, Frontend) | VPC |
| 3 | `customer-listener-rules.yaml` | `dev-{customer}-listener-rules` | 2 ALB Listener Rules (Backend, Frontend) | Shared ALB, Target Groups |
| 4 | `customer-tasks.yaml` | `dev-{customer}-tasks` | 3 Task Definitions (Backend API, Worker, Frontend) | Shared IAM, Logs, ECR Images |
| 5 | `customer-services.yaml` | `dev-{customer}-services` | 3 ECS Services (Backend API, Worker, Frontend) | Tasks, Target Groups, ECS Cluster |
| 6 | `customer-dns.yaml` | `dev-{customer}-dns` | 1 Route 53 A Record | Shared ALB |

**Per Customer Cost**: ~$38/month

### Alternative: Combined Customer Stack

| File | Stack Name | Description |
|------|------------|-------------|
| `customer-stack.yaml` | `dev-{customer}-stack` | All 6 customer resources in one file (not recommended for production) |

---

## Stack Naming Convention

```
Shared:     {environment}-{app-name}-{resource}
            Example: dev-task-manager-ecr

Per Customer: {environment}-{customer-name}-{resource}
              Example: dev-global-logs
                       dev-customer1-services
```

## Prerequisites

1. **Domain** registered in Route 53: `freeinterestcal.com`
2. **Wildcard SSL Certificate** in ACM: `*.freeinterestcal.com` (see setup below)
3. **AWS CLI** configured
4. **Docker** installed

## Setup SSL Certificate (One-time)

Before deploying, you need to create a wildcard SSL certificate in AWS Certificate Manager (ACM).

### Request Certificate

```bash
# Request wildcard certificate
aws acm request-certificate \
  --domain-name "*.freeinterestcal.com" \
  --subject-alternative-names "freeinterestcal.com" \
  --validation-method DNS \
  --region us-east-1

# Note the CertificateArn from the output
```

### Validate Certificate

```bash
# Get validation records
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/xxxxx \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[*].ResourceRecord'

# Add the CNAME records to Route 53 (or use AWS Console)
# The certificate will be validated automatically within a few minutes
```

### Get Certificate ARN

```bash
# List all certificates
aws acm list-certificates --region us-east-1

# Or get specific certificate ARN
aws acm list-certificates \
  --region us-east-1 \
  --query 'CertificateSummaryList[?DomainName==`*.freeinterestcal.com`].CertificateArn' \
  --output text
```

### Get Hosted Zone ID

```bash
# List hosted zones
aws route53 list-hosted-zones

# Or get specific zone ID
aws route53 list-hosted-zones \
  --query 'HostedZones[?Name==`freeinterestcal.com.`].Id' \
  --output text
```

## Manual Deployment

### Set Environment Variables

```bash
# Core settings
export ENVIRONMENT=dev
export REGION=us-east-1
export APP_NAME=task-manager

# Get AWS Account ID and ECR Registry
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Get SSL Certificate ARN (from ACM)
export WILDCARD_CERT_ARN=$(aws acm list-certificates \
  --region $REGION \
  --query 'CertificateSummaryList[?DomainName==`*.freeinterestcal.com`].CertificateArn' \
  --output text)

# Get Hosted Zone ID (from Route 53)
export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query 'HostedZones[?Name==`freeinterestcal.com.`].Id' \
  --output text | cut -d'/' -f3)

echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "ECR Registry: $ECR_REGISTRY"
echo "Certificate ARN: $WILDCARD_CERT_ARN"
echo "Hosted Zone ID: $HOSTED_ZONE_ID"
```

### Step 1: Deploy Shared Infrastructure (Once)

```bash
# 1. ECR Repository
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-ecr \
  --template-file shared-ecr.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --region $REGION

# 2. VPC (Public/Private subnets, NAT Gateway)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-vpc \
  --template-file shared-vpc.yaml \
  --parameter-overrides EnvironmentName=$ENVIRONMENT \
  --region $REGION

# 3. Security Groups (ALB, Backend API, Backend Worker, Frontend)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-sg \
  --template-file shared-security-groups.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --region $REGION

# 4. ECS Cluster (Fargate cluster)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-cluster \
  --template-file shared-ecs-cluster.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --region $REGION

# 5. Shared IAM Roles (used by all customers)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-iam \
  --template-file shared-iam.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

# 6. Shared ALB (with wildcard SSL certificate)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-shared-alb \
  --template-file shared-alb.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    WildcardCertificateArn=$WILDCARD_CERT_ARN \
  --region $REGION
```

### Step 2: Build and Push Docker Images

```bash
# Build and push images (required before deploying customers)
cd ../.. && ./build-and-push-versioned.sh latest $REGION && cd cloudformation/multi-customer
```

### Step 3: Deploy Global Customer (freeinterestcal.com)

```bash
# Set customer-specific variables
export CUSTOMER_NAME=global
export CUSTOMER_DOMAIN=freeinterestcal.com
export INSTANCE_DISPLAY_NAME="Global"
export BACKEND_PRIORITY=10
export FRONTEND_PRIORITY=11

# 1. CloudWatch Log Groups
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-logs \
  --template-file customer-logs.yaml \
  --parameter-overrides CustomerName=$CUSTOMER_NAME \
  --region $REGION

# 2. Target Groups (Backend API and Frontend)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-target-groups \
  --template-file customer-target-groups.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    CustomerName=$CUSTOMER_NAME \
  --region $REGION

# 3. Listener Rules (Host-based routing)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-listener-rules \
  --template-file customer-listener-rules.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    CustomerName=$CUSTOMER_NAME \
    CustomerDomain=$CUSTOMER_DOMAIN \
    BackendRulePriority=$BACKEND_PRIORITY \
    FrontendRulePriority=$FRONTEND_PRIORITY \
  --region $REGION

# 4. Task Definitions (Backend API, Backend Worker, Frontend)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-tasks \
  --template-file customer-tasks.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    CustomerName=$CUSTOMER_NAME \
    CustomerDomain=$CUSTOMER_DOMAIN \
    InstanceDisplayName="$INSTANCE_DISPLAY_NAME" \
    BackendImageURI=${ECR_REGISTRY}/${APP_NAME}:backend-api-latest \
    WorkerImageURI=${ECR_REGISTRY}/${APP_NAME}:backend-worker-latest \
    FrontendImageURI=${ECR_REGISTRY}/${APP_NAME}:frontend-latest \
  --region $REGION

# 5. ECS Services (Backend API, Backend Worker, Frontend)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-services \
  --template-file customer-services.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    CustomerName=$CUSTOMER_NAME \
    DesiredCountBackend=2 \
    DesiredCountWorker=1 \
    DesiredCountFrontend=2 \
  --region $REGION

# 6. Route 53 DNS Record
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-dns \
  --template-file customer-dns.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    CustomerName=$CUSTOMER_NAME \
    CustomerDomain=$CUSTOMER_DOMAIN \
    HostedZoneId=$HOSTED_ZONE_ID \
  --region $REGION
```

### Step 4: Deploy Customer 1 (customer1.freeinterestcal.com)

```bash
# Set customer-specific variables
export CUSTOMER_NAME=customer1
export CUSTOMER_DOMAIN=customer1.freeinterestcal.com
export INSTANCE_DISPLAY_NAME="Customer 1"
export BACKEND_PRIORITY=20
export FRONTEND_PRIORITY=21

# 1. CloudWatch Log Groups
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-logs \
  --template-file customer-logs.yaml \
  --parameter-overrides CustomerName=$CUSTOMER_NAME \
  --region $REGION

# 2. Target Groups
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-target-groups \
  --template-file customer-target-groups.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    CustomerName=$CUSTOMER_NAME \
  --region $REGION

# 3. Listener Rules
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-listener-rules \
  --template-file customer-listener-rules.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    CustomerName=$CUSTOMER_NAME \
    CustomerDomain=$CUSTOMER_DOMAIN \
    BackendRulePriority=$BACKEND_PRIORITY \
    FrontendRulePriority=$FRONTEND_PRIORITY \
  --region $REGION

# 4. Task Definitions
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-tasks \
  --template-file customer-tasks.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    CustomerName=$CUSTOMER_NAME \
    CustomerDomain=$CUSTOMER_DOMAIN \
    InstanceDisplayName="$INSTANCE_DISPLAY_NAME" \
    BackendImageURI=${ECR_REGISTRY}/${APP_NAME}:backend-api-latest \
    WorkerImageURI=${ECR_REGISTRY}/${APP_NAME}:backend-worker-latest \
    FrontendImageURI=${ECR_REGISTRY}/${APP_NAME}:frontend-latest \
  --region $REGION

# 5. ECS Services
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-services \
  --template-file customer-services.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    CustomerName=$CUSTOMER_NAME \
    DesiredCountBackend=2 \
    DesiredCountWorker=1 \
    DesiredCountFrontend=2 \
  --region $REGION

# 6. DNS Record
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-dns \
  --template-file customer-dns.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    CustomerName=$CUSTOMER_NAME \
    CustomerDomain=$CUSTOMER_DOMAIN \
    HostedZoneId=$HOSTED_ZONE_ID \
  --region $REGION
```

### Get ALB DNS

```bash
aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-shared-alb \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text
```

## Access Applications

After deployment completes (~10-15 minutes):

- **Global**: https://freeinterestcal.com
- **Customer 1**: https://customer1.freeinterestcal.com

Each instance will display its name in the UI header.

## Monitor Logs

```bash
# Global - Backend API
aws logs tail /ecs/global-backend-api --follow --region $REGION

# Global - Backend Worker
aws logs tail /ecs/global-backend-worker --follow --region $REGION

# Global - Frontend
aws logs tail /ecs/global-frontend --follow --region $REGION

# Customer 1 - Backend API
aws logs tail /ecs/customer1-backend-api --follow --region $REGION

# Customer 1 - Backend Worker
aws logs tail /ecs/customer1-backend-worker --follow --region $REGION

# Customer 1 - Frontend
aws logs tail /ecs/customer1-frontend --follow --region $REGION
```

## Update Services

After pushing new images:

```bash
# Update Global
aws ecs update-service \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service global-backend-api \
  --force-new-deployment \
  --region $REGION

aws ecs update-service \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service global-backend-worker \
  --force-new-deployment \
  --region $REGION

aws ecs update-service \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service global-frontend \
  --force-new-deployment \
  --region $REGION

# Update Customer 1
aws ecs update-service \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service customer1-backend-api \
  --force-new-deployment \
  --region $REGION

aws ecs update-service \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service customer1-backend-worker \
  --force-new-deployment \
  --region $REGION

aws ecs update-service \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service customer1-frontend \
  --force-new-deployment \
  --region $REGION
```

## Cleanup

### Delete a Customer (in reverse order)

```bash
# Set customer name
export CUSTOMER_NAME=global

# 6. DNS
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-dns --region $REGION

# 5. Services
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-services --region $REGION

# Wait for services to delete
aws cloudformation wait stack-delete-complete --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-services --region $REGION

# 4. Tasks
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-tasks --region $REGION

# 3. Listener Rules
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-listener-rules --region $REGION

# 2. Target Groups
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-target-groups --region $REGION

# 1. Logs
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-logs --region $REGION
```

### Delete Shared Infrastructure

After deleting all customers:

```bash
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-shared-alb --region $REGION
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-iam --region $REGION
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-cluster --region $REGION
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-sg --region $REGION
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-ecr --region $REGION
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-vpc --region $REGION
```

## Deployment Order & Dependencies

### Complete Deployment Flow

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1: SHARED INFRASTRUCTURE (Deploy Once)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. shared-ecr.yaml
   Stack: dev-task-manager-ecr
   └─ ECR Repository

2. shared-vpc.yaml
   Stack: dev-vpc
   └─ VPC, Subnets, NAT, IGW, Route Tables

3. shared-security-groups.yaml (depends on: VPC)
   Stack: dev-task-manager-sg
   └─ 4 Security Groups

4. shared-ecs-cluster.yaml
   Stack: dev-task-manager-cluster
   └─ ECS Cluster + Log Groups

5. shared-iam.yaml
   Stack: dev-task-manager-iam
   └─ Task Execution Role, Task Role

6. shared-alb.yaml (depends on: VPC, Security Groups, SSL Cert)
   Stack: dev-task-manager-shared-alb
   └─ ALB + HTTP/HTTPS Listeners

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 2: BUILD DOCKER IMAGES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

build-and-push-versioned.sh
└─ Builds and pushes 3 images to ECR

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 3: PER-CUSTOMER RESOURCES (Repeat for Each Customer)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. customer-logs.yaml
   Stack: dev-{customer}-logs
   └─ 3 CloudWatch Log Groups

2. customer-target-groups.yaml (depends on: VPC)
   Stack: dev-{customer}-target-groups
   └─ 2 Target Groups (Backend API, Frontend)

3. customer-listener-rules.yaml (depends on: ALB, Target Groups)
   Stack: dev-{customer}-listener-rules
   └─ 2 ALB Listener Rules (Priority-based routing)

4. customer-tasks.yaml (depends on: IAM, Logs, ECR Images)
   Stack: dev-{customer}-tasks
   └─ 3 Task Definitions (Backend API, Worker, Frontend)

5. customer-services.yaml (depends on: Tasks, Target Groups)
   Stack: dev-{customer}-services
   └─ 3 ECS Services (Backend API, Worker, Frontend)

6. customer-dns.yaml (depends on: ALB)
   Stack: dev-{customer}-dns
   └─ 1 Route 53 A Record

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Dependency Graph

```
shared-ecr.yaml ────────────────────────────┐
                                            │
shared-vpc.yaml ────────┬───────────────────┤
                        │                   │
                        ├─→ shared-security-groups.yaml
                        │                   │
shared-ecs-cluster.yaml │                   │
                        │                   │
shared-iam.yaml ────────┼───────────────────┤
                        │                   │
                        └─→ shared-alb.yaml │
                                            │
                                            ↓
                        ┌─── Build Docker Images ───┐
                        │                           │
                        ↓                           ↓
              customer-logs.yaml          customer-target-groups.yaml
                        │                           │
                        │         ┌─────────────────┤
                        │         │                 │
                        │         ↓                 │
                        │  customer-listener-rules.yaml
                        │         │                 │
                        └─────────┼─────────────────┤
                                  ↓                 │
                          customer-tasks.yaml       │
                                  │                 │
                                  └─────────────────┤
                                                    ↓
                                        customer-services.yaml
                                                    │
                                                    ↓
                                            customer-dns.yaml
```

## Priority Allocation

Each customer needs unique listener rule priorities:

| Customer | Domain | Backend Priority | Frontend Priority |
|----------|--------|------------------|-------------------|
| Global | freeinterestcal.com | 10 | 11 |
| Customer 1 | customer1.freeinterestcal.com | 20 | 21 |
| Customer 2 | customer2.freeinterestcal.com | 30 | 31 |

**Pattern**: Use (N+1)*10 for backend, (N+1)*10+1 for frontend where N is customer number.

## Service Details

### Port Configuration

| Service | Port | Exposed to ALB? | Purpose |
|---------|------|-----------------|---------|
| **Backend API** | 3001 | ✅ Yes | REST API endpoints (/api/*, /health) |
| **Backend Worker** | None | ❌ No | Background task processor (polls API) |
| **Frontend** | 3000 | ✅ Yes | React web application |

**Why worker has no port:**
- The worker is a background process that **polls** the backend API
- It makes HTTP requests **to** the API (as a client)
- It doesn't receive any incoming traffic
- No target group or ALB listener rule needed

### Security Group Configuration

| Service | Ingress (Inbound) | Egress (Outbound) | Why? |
|---------|-------------------|-------------------|------|
| **ALB** | 0.0.0.0/0:80, 0.0.0.0/0:443 | Backend:3001, Frontend:3000 | Receives internet traffic, forwards to services |
| **Backend API** | ALB:3001 | All (0.0.0.0/0) | Receives from ALB only |
| **Backend Worker** | **NONE** ❌ | All (0.0.0.0/0) | **No inbound traffic** - only makes outbound calls |
| **Frontend** | ALB:3000 | All (0.0.0.0/0) | Receives from ALB only |

**Key Point: Worker has NO ingress rules!**

The worker security group:
- ✅ **Egress (Outbound)**: Allows all traffic (so it can call Backend API on port 3001)
- ❌ **Ingress (Inbound)**: No rules - worker doesn't accept any connections

**Traffic Flow:**
```
Internet → ALB (port 443)
           ↓
      Backend API (port 3001) ← Worker polls this (outbound call)
           ↑
      Worker makes HTTP GET/POST requests
      (worker initiates connection, not backend)
```

## How It Works

### Host-Based Routing

The shared ALB routes traffic based on the `Host` header:

```
Request: https://customer1.freeinterestcal.com/api/tasks
         ↓
ALB checks Host header: "customer1.freeinterestcal.com"
         ↓
Matches listener rule priority 20
         ↓
Routes to customer1-backend-api-tg
         ↓
Forwards to customer1 backend ECS tasks
```

### Service Isolation

Each customer has:
- ✅ Separate ECS services
- ✅ Separate task definitions
- ✅ Separate target groups
- ✅ Separate CloudWatch logs
- ✅ Separate DNS records

Shared resources:
- ✅ VPC and subnets
- ✅ Security groups
- ✅ ECS cluster
- ✅ IAM roles (shared across all customers)
- ✅ ALB (with separate listener rules)
- ✅ ECR repository

## Cost Estimate

**Shared Infrastructure (~$81/month)**:
- NAT Gateway (2 AZs): ~$64/month
- ALB: ~$16/month + data transfer
- VPC, ECS Cluster, ECR: Minimal

**Per Customer (~$38/month)**:
- Backend API (2 tasks): ~$15/month
- Backend Worker (1 task): ~$7.50/month
- Frontend (2 tasks): ~$15/month
- CloudWatch Logs: ~$0.50/month
- Route 53 Record: ~$0.50/month

**Total for 2 Customers**: ~$157/month ($81 + $38 + $38)

**Savings**: Shared ALB saves ~$16/month per customer vs dedicated ALBs.

## Troubleshooting

### Check Stack Status

```bash
aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-services \
  --region $REGION
```

### Check Stack Events

```bash
aws cloudformation describe-stack-events \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-services \
  --max-items 20 \
  --region $REGION
```

### Check ECS Service Status

```bash
aws ecs describe-services \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --services global-backend-api customer1-backend-api \
  --region $REGION
```

### Check Target Health

```bash
# Get target group ARN from stack outputs
TG_ARN=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT}-${CUSTOMER_NAME}-target-groups \
  --query 'Stacks[0].Outputs[?OutputKey==`BackendAPITargetGroupArn`].OutputValue' \
  --output text \
  --region $REGION)

# Check health
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region $REGION
```

### View ALB Listener Rules

```bash
# Get HTTPS listener ARN
LISTENER_ARN=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-shared-alb \
  --query 'Stacks[0].Outputs[?OutputKey==`HTTPSListenerArn`].OutputValue' \
  --output text \
  --region $REGION)

# View all rules
aws elbv2 describe-rules \
  --listener-arn $LISTENER_ARN \
  --region $REGION
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   Route 53      │
                    │  DNS Records    │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   freeinterestcal.com  customer1.freeinterestcal.com
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   Shared ALB    │
                    │  (Port 80/443)  │
                    │  Wildcard SSL   │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   Host-based          Host-based
   Routing             Routing
   (Priority 10-11)    (Priority 20-21)
        │                    │
   ┌────▼────┐         ┌────▼────┐
   │ Global  │         │Customer1│
   │   TGs   │         │   TGs   │
   └────┬────┘         └────┬────┘
        │                    │
   ┌────▼────────┐     ┌────▼────────┐
   │   ECS       │     │   ECS       │
   │  Services   │     │  Services   │
   │             │     │             │
   │ • Backend   │     │ • Backend   │
   │ • Worker    │     │ • Worker    │
   │ • Frontend  │     │ • Frontend  │
   └─────────────┘     └─────────────┘
```

## Key Features

- **Shared ALB**: Single load balancer for all customers (cost-efficient)
- **Host-Based Routing**: Routes traffic based on domain name
- **Isolated Services**: Each customer has completely separate services
- **Custom Branding**: Instance name displayed in UI header
- **Independent Scaling**: Scale each customer independently
- **Wildcard SSL**: Single certificate covers all subdomains
- **Zero Downtime**: Rolling deployments with health checks
- **Separated Templates**: Easy to understand and modify each component
