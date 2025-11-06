# ECS Deployment Summary

## Created CloudFormation Templates

### Infrastructure (15 files)

1. **vpc-shared.yaml** - VPC with public/private subnets, NAT Gateway, Internet Gateway
2. **security-groups.yaml** - Security groups for ALB, backend-api, backend-worker, frontend
3. **ecr-repository.yaml** - ECR repository for container images
4. **ecs-cluster.yaml** - ECS Fargate cluster with CloudWatch log groups
5. **alb.yaml** - Application Load Balancer with path-based routing

### Task Definitions

6. **ecs-task-backend-api.yaml** - Backend API task (256 CPU, 512 MB)
7. **ecs-task-backend-worker.yaml** - Backend Worker task (256 CPU, 512 MB)
8. **ecs-task-frontend.yaml** - Frontend task (256 CPU, 512 MB)

### Services

9. **ecs-service-backend-api.yaml** - Backend API service (2 tasks)
10. **ecs-service-backend-worker.yaml** - Backend Worker service (1 task)
11. **ecs-service-frontend.yaml** - Frontend service (2 tasks)

### Scripts

12. **build-and-push.sh** - Build and push all 3 images to ECR
13. **deploy-all.sh** - Deploy all 11 CloudFormation stacks
14. **cleanup-all.sh** - Delete all stacks
15. **README.md** - Deployment documentation

## Deployment Flow

```
1. ECR Repository
2. VPC (with NAT Gateway)
3. Security Groups
4. ECS Cluster
5. Application Load Balancer
6. Backend API Task Definition
7. Backend Worker Task Definition
8. Frontend Task Definition
9. Backend API Service
10. Backend Worker Service
11. Frontend Service
```

## Architecture

```
Internet
    ↓
Application Load Balancer (Public Subnets)
    ↓
    ├─→ /api/* → Backend API (Private Subnets)
    │              ↑
    │              │ (polls queue)
    │              │
    │         Backend Worker (Private Subnets)
    │
    └─→ /* → Frontend (Private Subnets)
```

## Key Features

- **High Availability**: Multi-AZ deployment across 2 availability zones
- **Auto Scaling**: Ready for auto-scaling policies (not configured by default)
- **Security**: Private subnets for ECS tasks, security groups with minimal access
- **Logging**: CloudWatch Logs for all services
- **Container Insights**: Enabled for monitoring
- **Path-based Routing**: ALB routes API and frontend traffic appropriately

## Resource Naming Convention

Format: `{environment}-{app-name}-{resource-type}`

Examples:
- `dev-task-manager-cluster`
- `dev-task-manager-backend-api`
- `dev-task-manager-alb-sg`

## Environment Variables

### Backend API
- `NODE_ENV=production`
- `PORT=3001`

### Backend Worker
- `NODE_ENV=production`
- `API_URL=http://{alb-dns}` (automatically set)

### Frontend
- `REACT_APP_API_URL=http://{alb-dns}` (automatically set)

## Quick Commands

### Deploy
```bash
cd cloudformation
./build-and-push.sh latest us-east-1
./deploy-all.sh dev us-east-1
```

### Monitor
```bash
aws logs tail /ecs/dev-task-manager-backend-api --follow
aws logs tail /ecs/dev-task-manager-backend-worker --follow
aws logs tail /ecs/dev-task-manager-frontend --follow
```

### Update
```bash
./build-and-push.sh v1.0.1 us-east-1
aws ecs update-service --cluster dev-task-manager-cluster \
  --service dev-task-manager-backend-api --force-new-deployment
```

### Cleanup
```bash
./cleanup-all.sh dev us-east-1
```

## Cost Optimization

Current setup: ~$50/month

**To reduce costs:**
1. Use single AZ (remove one subnet pair)
2. Use public subnets for ECS tasks (remove NAT Gateway) - saves $32/month
3. Reduce task count (1 backend-api, 1 frontend, 1 worker) - saves $10/month
4. Use FARGATE_SPOT for non-critical workloads - saves 70%

## Differences from Reference

Adapted from `to-do-multi-dynamodb/cloudformation/`:

1. **3 services instead of 2**: Added backend-worker service
2. **Simplified naming**: `task-manager` vs `todo-app`
3. **No DynamoDB**: In-memory storage only
4. **Different ports**: 3001 (API) and 3000 (frontend) vs 4000 and 3000
5. **Minimal parameters**: Removed optional configurations for simplicity
6. **Combined scripts**: Single deploy-all.sh instead of multiple steps

## Next Steps

1. Add auto-scaling policies
2. Add HTTPS with ACM certificate
3. Add Route53 DNS
4. Add DynamoDB for persistence
5. Add CI/CD pipeline
6. Add CloudWatch alarms
7. Add X-Ray tracing

