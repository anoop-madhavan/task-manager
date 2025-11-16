# Manual GUI Setup Guide - Multi-Customer Task Manager

**Tags**: `v1-multi-customer-gui`, `v1-aws-console`, `v1-manual-setup`, `v1-learning-guide`

**Purpose**: Educational guide for learning AWS by manually creating resources via GUI

This guide walks you through manually creating AWS resources via the AWS Console GUI after deploying the foundational infrastructure (VPC, ECR, ECS Cluster, IAM, Security Groups) via CloudFormation.

> **Note**: This is a learning-focused approach. For production deployments, use the automated CloudFormation templates in the parent directory.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Part 1: Deploy Shared Infrastructure via CloudFormation](#part-1-deploy-shared-infrastructure-via-cloudformation)
4. [Part 2: Manual GUI Setup](#part-2-manual-gui-setup)
   - [A. Create Application Load Balancer (Shared)](#a-create-application-load-balancer-shared---once)
   - [B. Create Resources for Customer "Global"](#b-create-resources-for-customer-global-freeinterestcalcom)
   - [C. Create Resources for Customer 1](#c-create-resources-for-customer-1-customer1freeinterestcalcom)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Cleanup](#cleanup)

---

## Quick Reference

### Resource Naming Convention
```
Pattern: {customer-name}-{service}-{resource-type}

Examples:
- Log Groups: /ecs/global-backend-api
- Target Groups: global-backend-api-tg
- Task Definitions: global-backend-api
- Services: global-backend-api
```

### Customer Configuration Matrix

| Customer | Domain | Display Name | Backend Priority | Frontend Priority |
|----------|--------|--------------|------------------|-------------------|
| global | freeinterestcal.com | Global | 10 | 11 |
| customer1 | customer1.freeinterestcal.com | Customer 1 | 20 | 21 |
| customer2 | customer2.freeinterestcal.com | Customer 2 | 30 | 31 |

### Resources Per Customer

| Resource Type | Quantity | Names |
|---------------|----------|-------|
| CloudWatch Log Groups | 3 | backend-api, backend-worker, frontend |
| Target Groups | 2 | backend-api-tg, frontend-tg |
| ALB Listener Rules | 2 | backend-api, frontend |
| ECS Task Definitions | 3 | backend-api, backend-worker, frontend |
| ECS Services | 3 | backend-api, backend-worker, frontend |
| Route 53 DNS Records | 1 | A record pointing to ALB |

---

## Overview

**What you'll deploy via CloudFormation:**
- ✅ VPC with public/private subnets
- ✅ Security Groups (ALB, Backend API, Backend Worker, Frontend)
- ✅ ECS Fargate Cluster
- ✅ ECR Repository
- ✅ IAM Roles (Task Execution Role, Task Role)

**What you'll create manually via GUI:**
- 🖱️ Application Load Balancer (ALB) with HTTPS
- 🖱️ Target Groups (2 per customer)
- 🖱️ ALB Listener Rules (2 per customer)
- 🖱️ ECS Task Definitions (3 per customer)
- 🖱️ ECS Services (3 per customer)
- 🖱️ Route 53 DNS Records (1 per customer)
- 🖱️ CloudWatch Log Groups (3 per customer)

---

## Prerequisites

### 1. Domain Setup
- Domain registered in Route 53: `freeinterestcal.com`
- Hosted Zone created (automatic with Route 53 registration)

### 2. SSL Certificate
You need a wildcard SSL certificate in AWS Certificate Manager (ACM).

#### Create SSL Certificate (GUI):
1. Go to **AWS Certificate Manager** (ACM)
2. Click **Request a certificate**
3. Choose **Request a public certificate** → **Next**
4. Enter domain names:
   - `*.freeinterestcal.com`
   - `freeinterestcal.com`
5. Validation method: **DNS validation**
6. Click **Request**
7. Click **Create records in Route 53** (validates automatically)
8. Wait 5-10 minutes for validation to complete
9. **Copy the Certificate ARN** (you'll need this later)

---

## Part 1: Deploy Shared Infrastructure via CloudFormation

### Step 1: Deploy CloudFormation Stacks

Set environment variables:
```bash
export ENVIRONMENT=dev
export REGION=us-east-1
export APP_NAME=task-manager
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export WILDCARD_CERT_ARN="arn:aws:acm:us-east-1:YOUR_ACCOUNT:certificate/YOUR_CERT_ID"
```

Deploy stacks in order:
```bash
cd cloudformation/multi-customer

# 1. ECR Repository
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-ecr \
  --template-file shared-ecr.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --region $REGION

# 2. VPC
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-vpc \
  --template-file shared-vpc.yaml \
  --parameter-overrides EnvironmentName=$ENVIRONMENT \
  --region $REGION

# 3. Security Groups
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-sg \
  --template-file shared-security-groups.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --region $REGION

# 4. ECS Cluster
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-cluster \
  --template-file shared-ecs-cluster.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --region $REGION

# 5. IAM Roles
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-iam \
  --template-file shared-iam.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION
```

### Step 2: Build and Push Docker Images

```bash
# Login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Build and push images
cd ../..
./build-and-push-versioned.sh latest $REGION
```

---

## Part 2: Manual GUI Setup

Now we'll create the remaining resources manually via the AWS Console.

---

## A. Create Application Load Balancer (Shared - Once)

> **Note**: You can create the ALB in two ways - with HTTPS from the start (recommended) or HTTP-only first (simpler for learning). Both approaches are valid.

---

### Approach 1: ALB with HTTP Only (Simpler - Add HTTPS Later)

This approach creates the ALB without requiring the SSL certificate initially. You'll add HTTPS later.

#### 1. Navigate to EC2 → Load Balancers
- Go to **EC2 Console** → **Load Balancers** (left sidebar)
- Click **Create Load Balancer**

#### 2. Choose Load Balancer Type
- Select **Application Load Balancer**
- Click **Create**

#### 3. Basic Configuration
- **Name**: `dev-task-manager-shared-alb`
- **Scheme**: Internet-facing
- **IP address type**: IPv4

#### 4. Network Mapping
- **VPC**: Select `dev-task-manager-vpc`
- **Mappings**: Select both availability zones
  - **Subnet 1**: `dev-public-subnet-az1`
  - **Subnet 2**: `dev-public-subnet-az2`

#### 5. Security Groups
- Remove default security group
- Select: `dev-task-manager-alb-sg`

#### 6. Listeners and Routing

**HTTP Listener (Port 80):**
- **Protocol**: HTTP
- **Port**: 80
- **Default action**: Redirect to URL
  - Select **Redirect to URL**
  - **Protocol**: HTTPS
  - **Port**: 443
  - **Status code**: 301 - Permanently moved

> **Important**: When you select "Redirect", you do NOT need to select a target group! The redirect action sends traffic directly to HTTPS without touching any backend.

#### 7. Create Load Balancer
- Click **Create load balancer**
- Wait 3-5 minutes for provisioning
- **Copy the ALB DNS name** (e.g., `dev-task-manager-shared-alb-123456789.us-east-1.elb.amazonaws.com`)

#### 8. Add HTTPS Listener (After SSL Certificate is Ready)

Once you have your SSL certificate validated:

1. Go to **EC2** → **Load Balancers**
2. Select `dev-task-manager-shared-alb`
3. Click **Listeners** tab
4. Click **Add listener**
5. Configure:
   - **Protocol**: HTTPS
   - **Port**: 443
   - **Default action**: Return fixed response
     - **Response code**: 404
     - **Content type**: text/plain
     - **Response body**: `Instance not found. Please check your URL.`
   - **Secure listener settings**:
     - **Security policy**: ELBSecurityPolicy-TLS-1-2-2017-01
     - **Default SSL/TLS certificate**: 
       - From ACM
       - Select: `*.freeinterestcal.com`
6. Click **Add**

**Alternative via CLI:**
```bash
# Get certificate ARN
export WILDCARD_CERT_ARN=$(aws acm list-certificates \
  --region us-east-1 \
  --query 'CertificateSummaryList[?DomainName==`*.freeinterestcal.com`].CertificateArn' \
  --output text)

# Add HTTPS listener
aws elbv2 create-listener \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
    --names dev-task-manager-shared-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text) \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$WILDCARD_CERT_ARN \
  --ssl-policy ELBSecurityPolicy-TLS-1-2-2017-01 \
  --default-actions Type=fixed-response,FixedResponseConfig="{StatusCode=404,ContentType=text/plain,MessageBody='Instance not found. Please check your URL.'}" \
  --region us-east-1
```

---

### Approach 2: ALB with HTTPS from Start (Production-Ready)

This approach requires the SSL certificate to be ready before creating the ALB.

#### Prerequisites:
- ✅ SSL Certificate validated in ACM
- ✅ Certificate ARN copied

#### 1-5. Same as Approach 1 (Navigate, Choose Type, Basic Config, Network, Security Groups)

#### 6. Listeners and Routing

**HTTP Listener (Port 80):**
- **Protocol**: HTTP
- **Port**: 80
- **Default action**: Redirect to URL
  - Select **Redirect to URL**
  - **Protocol**: HTTPS
  - **Port**: 443
  - **Status code**: 301 - Permanently moved

**HTTPS Listener (Port 443):**
- Click **Add listener**
- **Protocol**: HTTPS
- **Port**: 443
- **Default action**: Return fixed response
  - Select **Return fixed response**
  - **Response code**: 404
  - **Content type**: text/plain
  - **Response body**: `Instance not found. Please check your URL.`
- **Secure listener settings**:
  - **Security policy**: ELBSecurityPolicy-TLS-1-2-2017-01
  - **Default SSL/TLS certificate**: 
    - From ACM
    - Select: `*.freeinterestcal.com`

> **Important**: Both listeners use actions (redirect/fixed-response) that do NOT require target groups!

#### 7. Create Load Balancer
- Click **Create load balancer**
- Wait 3-5 minutes for provisioning
- **Copy the ALB DNS name**

---

### Verify ALB Creation

```bash
# Check ALB status
aws elbv2 describe-load-balancers \
  --names dev-task-manager-shared-alb \
  --region us-east-1

# Check listeners
aws elbv2 describe-listeners \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
    --names dev-task-manager-shared-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text) \
  --region us-east-1

# Get ALB DNS name
aws elbv2 describe-load-balancers \
  --names dev-task-manager-shared-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region us-east-1
```

### What You Created:
- ✅ Application Load Balancer: `dev-task-manager-shared-alb`
- ✅ HTTP Listener (80) → Redirects to HTTPS (NO target group needed)
- ✅ HTTPS Listener (443) → Returns 404 by default (NO target group needed)
- ✅ SSL Certificate attached (if using Approach 2)
- ✅ Deployed in public subnets across 2 AZs
- ✅ **NO target groups created** (they'll be created per customer later)

### Key Insights:
- 🎯 **Redirect actions don't need target groups**
- 🎯 **Fixed-response actions don't need target groups**
- 🎯 **SSL certificate is only needed for HTTPS listener**
- 🎯 **You can create ALB first, add HTTPS later** (Approach 1)
- 🎯 **Target groups are created per customer, not during ALB setup**

---

## B. Create Resources for Customer "Global" (freeinterestcal.com)

### Customer Details:
- **Customer Name**: `global`
- **Domain**: `freeinterestcal.com`
- **Display Name**: `Global`
- **Backend Priority**: 10
- **Frontend Priority**: 11

---

### B1. Create CloudWatch Log Groups (3)

#### Backend API Log Group:
1. Go to **CloudWatch** → **Log groups**
2. Click **Create log group**
3. **Log group name**: `/ecs/global-backend-api`
4. **Retention**: 7 days
5. Click **Create**

#### Backend Worker Log Group:
1. Click **Create log group**
2. **Log group name**: `/ecs/global-backend-worker`
3. **Retention**: 7 days
4. Click **Create**

#### Frontend Log Group:
1. Click **Create log group**
2. **Log group name**: `/ecs/global-frontend`
3. **Retention**: 7 days
4. Click **Create**

---

### B2. Create Target Groups (2)

#### Backend API Target Group:
1. Go to **EC2** → **Target Groups**
2. Click **Create target group**
3. **Target type**: IP addresses
4. **Target group name**: `global-backend-api-tg`
5. **Protocol**: HTTP
6. **Port**: 3001
7. **VPC**: Select `dev-task-manager-vpc`
8. **Protocol version**: HTTP1
9. **Health check settings**:
   - **Health check protocol**: HTTP
   - **Health check path**: `/health`
   - **Advanced health check settings**:
     - **Healthy threshold**: 2
     - **Unhealthy threshold**: 3
     - **Timeout**: 5 seconds
     - **Interval**: 30 seconds
     - **Success codes**: 200
10. Click **Next**
11. Skip registering targets (ECS will do this automatically)
12. Click **Create target group**

#### Frontend Target Group:
1. Click **Create target group**
2. **Target type**: IP addresses
3. **Target group name**: `global-frontend-tg`
4. **Protocol**: HTTP
5. **Port**: 3000
6. **VPC**: Select `dev-task-manager-vpc`
7. **Protocol version**: HTTP1
8. **Health check settings**:
   - **Health check protocol**: HTTP
   - **Health check path**: `/`
   - **Advanced health check settings**:
     - **Healthy threshold**: 2
     - **Unhealthy threshold**: 3
     - **Timeout**: 5 seconds
     - **Interval**: 30 seconds
     - **Success codes**: 200
9. Click **Next**
10. Skip registering targets
11. Click **Create target group**

**Note**: Worker doesn't need a target group (no incoming traffic).

---

### B3. Create ALB Listener Rules (2)

#### Backend API Rule (Priority 10):
1. Go to **EC2** → **Load Balancers**
2. Select your ALB: `dev-task-manager-shared-alb`
3. Click **Listeners** tab
4. Select the **HTTPS:443** listener
5. Click **Manage rules**
6. Click **Add rule** (+ icon at top)
7. **Add condition**:
   - **Rule condition type**: Host header
   - **Host header**: `freeinterestcal.com`
8. Click **Next**
9. **Add action**:
   - **Routing action**: Forward to target group
   - **Target group**: `global-backend-api-tg`
10. Click **Next**
11. **Rule priority**: 10
12. **Rule name**: `global-backend-api`
13. Click **Next** → **Create**

#### Frontend Rule (Priority 11):
1. Click **Add rule** again
2. **Add condition**:
   - **Rule condition type**: Host header
   - **Host header**: `freeinterestcal.com`
3. Click **Next**
4. **Add action**:
   - **Routing action**: Forward to target group
   - **Target group**: `global-frontend-tg`
5. Click **Next**
6. **Rule priority**: 11
7. **Rule name**: `global-frontend`
8. Click **Next** → **Create**

**Note**: The backend rule (priority 10) will match `/api/*` requests, and frontend rule (priority 11) will match all other requests.

---

### B4. Create ECS Task Definitions (3)

Get the image URIs:
```bash
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
echo "Backend API: ${ECR_REGISTRY}/task-manager:backend-api-latest"
echo "Worker: ${ECR_REGISTRY}/task-manager:backend-worker-latest"
echo "Frontend: ${ECR_REGISTRY}/task-manager:frontend-latest"
```

#### Backend API Task Definition:
1. Go to **ECS** → **Task Definitions**
2. Click **Create new task definition** → **Create new task definition**
3. **Task definition family**: `global-backend-api`
4. **Launch type**: AWS Fargate
5. **Operating system/Architecture**: Linux/X86_64
6. **Task size**:
   - **CPU**: 0.25 vCPU
   - **Memory**: 0.5 GB
7. **Task role**: `dev-task-manager-task-role`
8. **Task execution role**: `dev-task-manager-task-execution-role`

9. **Container - 1**:
   - Click **Add container**
   - **Container name**: `backend-api`
   - **Image URI**: `YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/task-manager:backend-api-latest`
   - **Port mappings**:
     - **Container port**: 3001
     - **Protocol**: TCP
     - **Port name**: `backend-api-3001-tcp`
     - **App protocol**: HTTP
   - **Environment variables**:
     - `NODE_ENV` = `production`
     - `PORT` = `3001`
     - `INSTANCE_NAME` = `Global`
   - **Log collection**:
     - Check **Use log collection**
     - **Log driver**: awslogs
     - **awslogs-group**: `/ecs/global-backend-api`
     - **awslogs-region**: `us-east-1`
     - **awslogs-stream-prefix**: `ecs`

10. Click **Create**

#### Backend Worker Task Definition:
1. Click **Create new task definition**
2. **Task definition family**: `global-backend-worker`
3. **Launch type**: AWS Fargate
4. **Operating system/Architecture**: Linux/X86_64
5. **Task size**:
   - **CPU**: 0.25 vCPU
   - **Memory**: 0.5 GB
6. **Task role**: `dev-task-manager-task-role`
7. **Task execution role**: `dev-task-manager-task-execution-role`

8. **Container - 1**:
   - **Container name**: `backend-worker`
   - **Image URI**: `YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/task-manager:backend-worker-latest`
   - **Port mappings**: None (worker doesn't expose ports)
   - **Environment variables**:
     - `NODE_ENV` = `production`
     - `API_URL` = `https://freeinterestcal.com`
     - `INSTANCE_NAME` = `Global`
   - **Log collection**:
     - Check **Use log collection**
     - **awslogs-group**: `/ecs/global-backend-worker`
     - **awslogs-region**: `us-east-1`
     - **awslogs-stream-prefix**: `ecs`

9. Click **Create**

#### Frontend Task Definition:
1. Click **Create new task definition**
2. **Task definition family**: `global-frontend`
3. **Launch type**: AWS Fargate
4. **Operating system/Architecture**: Linux/X86_64
5. **Task size**:
   - **CPU**: 0.25 vCPU
   - **Memory**: 0.5 GB
6. **Task role**: `dev-task-manager-task-role`
7. **Task execution role**: `dev-task-manager-task-execution-role`

8. **Container - 1**:
   - **Container name**: `frontend`
   - **Image URI**: `YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/task-manager:frontend-latest`
   - **Port mappings**:
     - **Container port**: 3000
     - **Protocol**: TCP
     - **Port name**: `frontend-3000-tcp`
     - **App protocol**: HTTP
   - **Environment variables**:
     - `REACT_APP_API_URL` = `https://freeinterestcal.com`
     - `REACT_APP_INSTANCE_NAME` = `Global`
   - **Log collection**:
     - Check **Use log collection**
     - **awslogs-group**: `/ecs/global-frontend`
     - **awslogs-region**: `us-east-1`
     - **awslogs-stream-prefix**: `ecs`

9. Click **Create**

---

### B5. Create ECS Services (3)

#### Backend API Service:
1. Go to **ECS** → **Clusters**
2. Click on `dev-task-manager-cluster`
3. Click **Services** tab → **Create**
4. **Compute options**: Launch type
5. **Launch type**: FARGATE
6. **Application type**: Service
7. **Task definition**:
   - **Family**: `global-backend-api`
   - **Revision**: Latest
8. **Service name**: `global-backend-api`
9. **Desired tasks**: 2

10. **Networking**:
    - **VPC**: `dev-task-manager-vpc`
    - **Subnets**: Select both private subnets
      - `dev-private-subnet-az1`
      - `dev-private-subnet-az2`
    - **Security group**: `dev-task-manager-backend-api-sg`
    - **Public IP**: Disabled

11. **Load balancing**:
    - **Load balancer type**: Application Load Balancer
    - **Load balancer**: Select `dev-task-manager-shared-alb`
    - **Listener**: Use an existing listener → **443:HTTPS**
    - **Target group**: Use an existing target group → `global-backend-api-tg`
    - **Health check grace period**: 60 seconds

12. Click **Create**

#### Backend Worker Service:
1. Click **Create** (new service)
2. **Compute options**: Launch type
3. **Launch type**: FARGATE
4. **Application type**: Service
5. **Task definition**:
   - **Family**: `global-backend-worker`
   - **Revision**: Latest
6. **Service name**: `global-backend-worker`
7. **Desired tasks**: 1

8. **Networking**:
   - **VPC**: `dev-task-manager-vpc`
   - **Subnets**: Select both private subnets
   - **Security group**: `dev-task-manager-backend-worker-sg`
   - **Public IP**: Disabled

9. **Load balancing**: None (worker doesn't need ALB)

10. Click **Create**

#### Frontend Service:
1. Click **Create** (new service)
2. **Compute options**: Launch type
3. **Launch type**: FARGATE
4. **Application type**: Service
5. **Task definition**:
   - **Family**: `global-frontend`
   - **Revision**: Latest
6. **Service name**: `global-frontend`
7. **Desired tasks**: 2

8. **Networking**:
   - **VPC**: `dev-task-manager-vpc`
   - **Subnets**: Select both private subnets
   - **Security group**: `dev-task-manager-frontend-sg`
   - **Public IP**: Disabled

9. **Load balancing**:
   - **Load balancer type**: Application Load Balancer
   - **Load balancer**: Select `dev-task-manager-shared-alb`
   - **Listener**: Use an existing listener → **443:HTTPS**
   - **Target group**: Use an existing target group → `global-frontend-tg`
   - **Health check grace period**: 60 seconds

10. Click **Create**

---

### B6. Create Route 53 DNS Record

1. Go to **Route 53** → **Hosted zones**
2. Click on `freeinterestcal.com`
3. Click **Create record**
4. **Record name**: Leave empty (apex domain)
5. **Record type**: A
6. **Alias**: Toggle ON
7. **Route traffic to**:
   - **Alias to**: Application and Classic Load Balancer
   - **Region**: us-east-1
   - **Load balancer**: Select `dev-task-manager-shared-alb`
8. Click **Create records**

---

## C. Create Resources for Customer 1 (customer1.freeinterestcal.com)

Repeat all steps from Part B with these changes:

### Customer Details:
- **Customer Name**: `customer1`
- **Domain**: `customer1.freeinterestcal.com`
- **Display Name**: `Customer 1`
- **Backend Priority**: 20
- **Frontend Priority**: 21

### Resource Names:
- Log groups: `/ecs/customer1-backend-api`, `/ecs/customer1-backend-worker`, `/ecs/customer1-frontend`
- Target groups: `customer1-backend-api-tg`, `customer1-frontend-tg`
- Task definitions: `customer1-backend-api`, `customer1-backend-worker`, `customer1-frontend`
- Services: `customer1-backend-api`, `customer1-backend-worker`, `customer1-frontend`
- Listener rules: Priority 20 and 21
- Host header: `customer1.freeinterestcal.com`
- Environment variables:
  - `API_URL` = `https://customer1.freeinterestcal.com`
  - `REACT_APP_API_URL` = `https://customer1.freeinterestcal.com`
  - `INSTANCE_NAME` = `Customer 1`
  - `REACT_APP_INSTANCE_NAME` = `Customer 1`

### Route 53 DNS Record:
- **Record name**: `customer1`
- Rest same as global

---

## Verification

### 1. Check Target Health
1. Go to **EC2** → **Target Groups**
2. Select each target group
3. Click **Targets** tab
4. Wait for **Health status** to show "healthy" (may take 2-3 minutes)

### 2. Check ECS Services
1. Go to **ECS** → **Clusters** → `dev-task-manager-cluster`
2. Click **Services** tab
3. Verify all services show:
   - **Desired tasks**: Matches configuration
   - **Running tasks**: Matches desired
   - **Status**: Active

### 3. Check CloudWatch Logs
1. Go to **CloudWatch** → **Log groups**
2. Click on each log group
3. Verify log streams are being created
4. Check for any errors

### 4. Test Applications
Wait 5-10 minutes for DNS propagation, then access:
- **Global**: https://freeinterestcal.com
- **Customer 1**: https://customer1.freeinterestcal.com

You should see the task manager UI with the instance name displayed in the header.

---

## Architecture Summary

```
Internet
   ↓
Route 53 (freeinterestcal.com, customer1.freeinterestcal.com)
   ↓
Shared ALB (HTTPS with wildcard SSL)
   ↓
Host-based Routing (Listener Rules)
   ├─ Priority 10-11: freeinterestcal.com → Global Target Groups
   └─ Priority 20-21: customer1.freeinterestcal.com → Customer1 Target Groups
   ↓
Target Groups
   ├─ global-backend-api-tg (port 3001)
   ├─ global-frontend-tg (port 3000)
   ├─ customer1-backend-api-tg (port 3001)
   └─ customer1-frontend-tg (port 3000)
   ↓
ECS Services (in dev-task-manager-cluster)
   ├─ global-backend-api (2 tasks)
   ├─ global-backend-worker (1 task, no ALB)
   ├─ global-frontend (2 tasks)
   ├─ customer1-backend-api (2 tasks)
   ├─ customer1-backend-worker (1 task, no ALB)
   └─ customer1-frontend (2 tasks)
```

---

## Key Concepts

### Why Worker Has No Target Group or ALB?
The worker is a **background process** that:
- Polls the backend API via HTTP requests (as a client)
- Doesn't receive any incoming traffic
- Doesn't need to be exposed to the load balancer
- Only needs **outbound** network access

### Host-Based Routing
The ALB uses the `Host` header to route traffic:
- Request to `freeinterestcal.com` → Routes to global target groups
- Request to `customer1.freeinterestcal.com` → Routes to customer1 target groups

### Priority Numbers
- Lower priority number = Higher precedence
- Each customer needs unique priorities
- Pattern: Customer N uses (N+1)*10 and (N+1)*10+1

### Security Groups
- **ALB SG**: Allows inbound 80/443 from internet, outbound to ECS services
- **Backend API SG**: Allows inbound 3001 from ALB only
- **Worker SG**: No inbound rules (only outbound)
- **Frontend SG**: Allows inbound 3000 from ALB only

---

## Troubleshooting

### Services Not Starting
- Check CloudWatch logs for errors
- Verify security groups allow traffic
- Ensure task execution role has ECR permissions
- Check if images exist in ECR

### Target Health Checks Failing
- Verify health check path is correct (`/health` for backend, `/` for frontend)
- Check security groups allow ALB → ECS traffic
- Verify containers are listening on correct ports
- Check CloudWatch logs for application errors

### DNS Not Resolving
- Wait 5-10 minutes for DNS propagation
- Verify Route 53 record points to correct ALB
- Check ALB is in "active" state
- Use `dig` or `nslookup` to verify DNS

### 404 Errors
- Verify listener rules are configured correctly
- Check rule priorities don't conflict
- Ensure Host header matches exactly
- Verify target groups have healthy targets

---

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

**Total for 2 Customers**: ~$157/month

---

## Next Steps

### Add More Customers
Repeat Part C with new customer details:
- Customer 2: Priority 30-31, domain `customer2.freeinterestcal.com`
- Customer 3: Priority 40-41, domain `customer3.freeinterestcal.com`

### Update Services
When you push new Docker images:
1. Go to **ECS** → **Clusters** → `dev-task-manager-cluster`
2. Select service
3. Click **Update**
4. Check **Force new deployment**
5. Click **Update**

### Monitor Performance
- Use CloudWatch metrics to monitor CPU/Memory
- Set up alarms for unhealthy targets
- Monitor ALB request counts and latencies

### Scale Services
To handle more traffic:
1. Go to service
2. Click **Update**
3. Change **Desired tasks** count
4. Click **Update**

---

## Cleanup

### Delete Customer Resources (in reverse order):
1. Delete Route 53 record
2. Delete ECS services (wait for deletion)
3. Delete ALB listener rules
4. Delete target groups
5. Delete task definitions (can't be deleted, just deregister)
6. Delete CloudWatch log groups

### Delete Shared Resources:
1. Delete ALB
2. Delete CloudFormation stacks (in reverse order):
   ```bash
   aws cloudformation delete-stack --stack-name dev-task-manager-iam
   aws cloudformation delete-stack --stack-name dev-task-manager-cluster
   aws cloudformation delete-stack --stack-name dev-task-manager-sg
   aws cloudformation delete-stack --stack-name dev-task-manager-ecr
   aws cloudformation delete-stack --stack-name dev-vpc
   ```

---

## Learning Outcomes

By completing this manual setup, you'll understand:
- ✅ How ALB host-based routing works
- ✅ How target groups connect ALB to ECS
- ✅ How ECS task definitions define containers
- ✅ How ECS services manage task lifecycle
- ✅ How security groups control network traffic
- ✅ How CloudWatch logs capture container output
- ✅ How Route 53 DNS points to ALB
- ✅ How multi-tenant architecture isolates customers
- ✅ How Fargate removes server management overhead

This hands-on experience is invaluable for understanding AWS container orchestration!

---

## Document Metadata

**Document ID**: `v1-multi-customer-gui-setup`  
**Version**: 1.0  
**Last Updated**: 2025-11-12  
**Tags**: `v1-multi-customer-gui`, `v1-aws-console`, `v1-manual-setup`, `v1-learning-guide`, `v1-ecs`, `v1-fargate`, `v1-alb`, `v1-multi-tenant`, `v1-route53`, `v1-cloudwatch`, `v1-target-groups`, `v1-task-definitions`, `v1-ecs-services`, `v1-security-groups`  
**Difficulty**: Intermediate  
**Estimated Time**: 2-3 hours  
**AWS Services**: ECS, Fargate, ALB, Route 53, CloudWatch, ECR, VPC, IAM  

**Related Documents**:
- [README.md](./README.md) - Automated CloudFormation deployment
- [../../ARCHITECTURE.md](../../ARCHITECTURE.md) - Overall architecture
- [../../README.md](../../README.md) - Project overview

**Use Case**: Educational/Learning - Manual GUI setup for understanding AWS services  
**Production Ready**: No - Use CloudFormation templates for production deployments

