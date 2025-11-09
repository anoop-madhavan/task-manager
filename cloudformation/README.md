# Task Manager - ECS Deployment

CloudFormation templates for deploying Task Manager to AWS ECS Fargate.

## Architecture

- **VPC**: Public/private subnets across 2 AZs with NAT Gateway
- **ECS Cluster**: Fargate cluster with 3 services
  - Backend API (2 tasks)
  - Backend Worker (1 task)
  - Frontend (2 tasks)
- **ALB**: Routes `/api/*` to backend, `/` to frontend
- **ECR**: Container image repository

## Quick Start

### 1. Build and Push Images

```bash
cd cloudformation
./build-and-push.sh latest us-east-1
```

### 2. Deploy Infrastructure

```bash
./deploy-all.sh dev us-east-1
```

### 3. Access Application

After deployment completes (~10 minutes), access via ALB DNS:
```
http://<alb-dns-name>
```

## Files

| File | Description |
|------|-------------|
| `vpc-shared.yaml` | VPC with public/private subnets |
| `security-groups.yaml` | Security groups for ALB and ECS |
| `ecr-repository.yaml` | ECR repository |
| `ecs-cluster.yaml` | ECS cluster and log groups |
| `alb.yaml` | Application Load Balancer |
| `ecs-task-backend-api.yaml` | Backend API task definition |
| `ecs-task-backend-worker.yaml` | Backend Worker task definition |
| `ecs-task-frontend.yaml` | Frontend task definition |
| `ecs-service-backend-api.yaml` | Backend API service |
| `ecs-service-backend-worker.yaml` | Backend Worker service |
| `ecs-service-frontend.yaml` | Frontend service |
| `build-and-push.sh` | Build and push Docker images |
| `deploy-all.sh` | Deploy all stacks |
| `cleanup-all.sh` | Delete all stacks |

## Stack Organization

### Why ALB and Target Groups are in One Stack

**Correct Approach** ✅: ALB + Target Groups together in `alb.yaml`

**Reasoning**:
- Target Groups are **tightly coupled** to the ALB
- Target Groups cannot exist without an ALB
- Listener rules reference both ALB and Target Groups
- Simplifies deployment and reduces cross-stack dependencies
- Easier to manage routing changes

**Alternative (Not Recommended)** ❌: Separate stacks would require:
- Complex cross-stack references
- More deployment steps
- Harder to update routing rules
- No real benefit for this architecture

## Manual Deployment

### Set Environment Variables

```bash
# Set these first to avoid repetition
export ENVIRONMENT=dev
export REGION=us-east-1
export APP_NAME=task-manager
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "ECR Registry: $ECR_REGISTRY"
```

### Deployment Steps

```bash
# 1. ECR Repository
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-ecr \
  --template-file ecr-repository.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --region $REGION

# 2. VPC (Public/Private subnets, NAT Gateway)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-vpc \
  --template-file vpc-shared.yaml \
  --parameter-overrides EnvironmentName=$ENVIRONMENT \
  --region $REGION

# 3. Security Groups (ALB, Backend API, Backend Worker, Frontend)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-sg \
  --template-file security-groups.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --region $REGION

# 4. ECS Cluster (Fargate cluster + CloudWatch log groups)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-cluster \
  --template-file ecs-cluster.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --region $REGION

# 5. ALB + Target Groups (Single stack - tightly coupled)
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-alb \
  --template-file alb.yaml \
  --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
  --region $REGION

# 6. Build and push images (required before task definitions)
cd .. && ./cloudformation/build-and-push.sh latest $REGION && cd cloudformation

# 7. Backend API Task Definition
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-task-backend-api \
  --template-file ecs-task-backend-api.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    ECRImageURI=${ECR_REGISTRY}/${APP_NAME}:backend-api-latest \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

# 8. Backend Worker Task Definition
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-task-backend-worker \
  --template-file ecs-task-backend-worker.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    ECRImageURI=${ECR_REGISTRY}/${APP_NAME}:backend-worker-latest \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

# 9. Frontend Task Definition
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-task-frontend \
  --template-file ecs-task-frontend.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    ECRImageURI=${ECR_REGISTRY}/${APP_NAME}:frontend-latest \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

# 10. Backend API Service
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-service-backend-api \
  --template-file ecs-service-backend-api.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    DesiredCount=2 \
  --region $REGION

# 11. Backend Worker Service
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-service-backend-worker \
  --template-file ecs-service-backend-worker.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    DesiredCount=1 \
  --region $REGION

# 12. Frontend Service
aws cloudformation deploy \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-service-frontend \
  --template-file ecs-service-frontend.yaml \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    AppName=$APP_NAME \
    DesiredCount=2 \
  --region $REGION
```

### Get ALB DNS

```bash
aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-alb \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text
```

## Monitor Logs

```bash
# Using environment variables (set above)
aws logs tail /ecs/${ENVIRONMENT}-${APP_NAME}-backend-api --follow --region $REGION
aws logs tail /ecs/${ENVIRONMENT}-${APP_NAME}-backend-worker --follow --region $REGION
aws logs tail /ecs/${ENVIRONMENT}-${APP_NAME}-frontend --follow --region $REGION

# Or without variables
aws logs tail /ecs/dev-task-manager-backend-api --follow --region us-east-1
```

## Update Services

After pushing new images:

```bash
# Using environment variables
aws ecs update-service \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service ${ENVIRONMENT}-${APP_NAME}-backend-api \
  --force-new-deployment \
  --region $REGION

aws ecs update-service \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service ${ENVIRONMENT}-${APP_NAME}-backend-worker \
  --force-new-deployment \
  --region $REGION

aws ecs update-service \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service ${ENVIRONMENT}-${APP_NAME}-frontend \
  --force-new-deployment \
  --region $REGION
```

## Cleanup

```bash
# Using script
./cleanup-all.sh $ENVIRONMENT $REGION

# Or manually
./cleanup-all.sh dev us-east-1
```

## Cost Estimate

**Dev environment (~$50/month)**:
- NAT Gateway: ~$32/month
- ALB: ~$16/month
- Fargate: ~$15/month (5 tasks × 0.25 vCPU × 0.5 GB)
- Data transfer: Variable

**Reduce costs**: Use single AZ, remove NAT Gateway (use public subnets), reduce task count.

