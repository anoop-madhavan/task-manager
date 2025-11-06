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

## Manual Deployment

```bash
# 1. ECR
aws cloudformation deploy --stack-name dev-task-manager-ecr \
  --template-file ecr-repository.yaml \
  --parameter-overrides Environment=dev AppName=task-manager

# 2. VPC
aws cloudformation deploy --stack-name dev-vpc \
  --template-file vpc-shared.yaml \
  --parameter-overrides EnvironmentName=dev

# 3. Security Groups
aws cloudformation deploy --stack-name dev-task-manager-sg \
  --template-file security-groups.yaml \
  --parameter-overrides Environment=dev AppName=task-manager

# 4. ECS Cluster
aws cloudformation deploy --stack-name dev-task-manager-cluster \
  --template-file ecs-cluster.yaml \
  --parameter-overrides Environment=dev AppName=task-manager

# 5. ALB
aws cloudformation deploy --stack-name dev-task-manager-alb \
  --template-file alb.yaml \
  --parameter-overrides Environment=dev AppName=task-manager

# 6-8. Task Definitions (after building images)
aws cloudformation deploy --stack-name dev-task-manager-task-backend-api \
  --template-file ecs-task-backend-api.yaml \
  --parameter-overrides Environment=dev AppName=task-manager \
    ECRImageURI=<account-id>.dkr.ecr.us-east-1.amazonaws.com/task-manager:backend-api-latest \
  --capabilities CAPABILITY_NAMED_IAM

# 9-11. Services
aws cloudformation deploy --stack-name dev-task-manager-service-backend-api \
  --template-file ecs-service-backend-api.yaml \
  --parameter-overrides Environment=dev AppName=task-manager
```

## Monitor Logs

```bash
aws logs tail /ecs/dev-task-manager-backend-api --follow
aws logs tail /ecs/dev-task-manager-backend-worker --follow
aws logs tail /ecs/dev-task-manager-frontend --follow
```

## Update Services

After pushing new images:

```bash
aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service dev-task-manager-backend-api \
  --force-new-deployment

aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service dev-task-manager-backend-worker \
  --force-new-deployment

aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service dev-task-manager-frontend \
  --force-new-deployment
```

## Cleanup

```bash
./cleanup-all.sh dev us-east-1
```

## Cost Estimate

**Dev environment (~$50/month)**:
- NAT Gateway: ~$32/month
- ALB: ~$16/month
- Fargate: ~$15/month (5 tasks × 0.25 vCPU × 0.5 GB)
- Data transfer: Variable

**Reduce costs**: Use single AZ, remove NAT Gateway (use public subnets), reduce task count.

