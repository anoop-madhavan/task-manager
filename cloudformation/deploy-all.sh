#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}
APP_NAME="task-manager"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Usage: $0 [environment] [region]"
    echo "Environment must be: dev, staging, or prod"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo -e "${BLUE}Task Manager - CloudFormation Deployment${NC}"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "AWS Account: $AWS_ACCOUNT_ID"
echo ""

# Step 1: ECR Repository
echo -e "${YELLOW}[1/11] Creating ECR Repository...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-ecr \
    --template-file ecr-repository.yaml \
    --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ ECR Repository ready${NC}"

# Step 2: VPC
echo -e "\n${YELLOW}[2/11] Creating VPC...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-vpc \
    --template-file vpc-shared.yaml \
    --parameter-overrides EnvironmentName=$ENVIRONMENT \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ VPC ready${NC}"

# Step 3: Security Groups
echo -e "\n${YELLOW}[3/11] Creating Security Groups...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-sg \
    --template-file security-groups.yaml \
    --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ Security Groups ready${NC}"

# Step 4: ECS Cluster
echo -e "\n${YELLOW}[4/11] Creating ECS Cluster...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-cluster \
    --template-file ecs-cluster.yaml \
    --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ ECS Cluster ready${NC}"

# Step 5: ALB
echo -e "\n${YELLOW}[5/11] Creating Application Load Balancer...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-alb \
    --template-file alb.yaml \
    --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ ALB ready${NC}"

# Get ALB DNS
ALB_DNS=$(aws cloudformation describe-stacks \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-alb \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
    --output text)

# Check images
echo -e "\n${YELLOW}Checking Docker images...${NC}"
BACKEND_API_IMAGE="${ECR_REGISTRY}/${APP_NAME}:backend-api-latest"
BACKEND_WORKER_IMAGE="${ECR_REGISTRY}/${APP_NAME}:backend-worker-latest"
FRONTEND_IMAGE="${ECR_REGISTRY}/${APP_NAME}:frontend-latest"

if ! aws ecr describe-images --repository-name $APP_NAME --image-ids imageTag=backend-api-latest --region $REGION &> /dev/null; then
    echo "Error: backend-api image not found. Run: ./build-and-push.sh"
    exit 1
fi
if ! aws ecr describe-images --repository-name $APP_NAME --image-ids imageTag=backend-worker-latest --region $REGION &> /dev/null; then
    echo "Error: backend-worker image not found. Run: ./build-and-push.sh"
    exit 1
fi
if ! aws ecr describe-images --repository-name $APP_NAME --image-ids imageTag=frontend-latest --region $REGION &> /dev/null; then
    echo "Error: frontend image not found. Run: ./build-and-push.sh"
    exit 1
fi
echo -e "${GREEN}✓ All images found${NC}"

# Step 6: Backend API Task Definition
echo -e "\n${YELLOW}[6/11] Creating Backend API Task Definition...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-task-backend-api \
    --template-file ecs-task-backend-api.yaml \
    --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME ECRImageURI=$BACKEND_API_IMAGE \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ Backend API Task Definition ready${NC}"

# Step 7: Backend Worker Task Definition
echo -e "\n${YELLOW}[7/11] Creating Backend Worker Task Definition...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-task-backend-worker \
    --template-file ecs-task-backend-worker.yaml \
    --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME ECRImageURI=$BACKEND_WORKER_IMAGE \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ Backend Worker Task Definition ready${NC}"

# Step 8: Frontend Task Definition
echo -e "\n${YELLOW}[8/11] Creating Frontend Task Definition...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-task-frontend \
    --template-file ecs-task-frontend.yaml \
    --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME ECRImageURI=$FRONTEND_IMAGE \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ Frontend Task Definition ready${NC}"

# Step 9: Backend API Service
echo -e "\n${YELLOW}[9/11] Creating Backend API Service...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-service-backend-api \
    --template-file ecs-service-backend-api.yaml \
    --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME DesiredCount=2 \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ Backend API Service ready${NC}"

# Step 10: Backend Worker Service
echo -e "\n${YELLOW}[10/11] Creating Backend Worker Service...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-service-backend-worker \
    --template-file ecs-service-backend-worker.yaml \
    --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME DesiredCount=1 \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ Backend Worker Service ready${NC}"

# Step 11: Frontend Service
echo -e "\n${YELLOW}[11/11] Creating Frontend Service...${NC}"
aws cloudformation deploy \
    --stack-name ${ENVIRONMENT}-${APP_NAME}-service-frontend \
    --template-file ecs-service-frontend.yaml \
    --parameter-overrides Environment=$ENVIRONMENT AppName=$APP_NAME DesiredCount=2 \
    --region $REGION \
    --no-fail-on-empty-changeset
echo -e "${GREEN}✓ Frontend Service ready${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Application URL: http://$ALB_DNS"
echo "Backend API: http://$ALB_DNS/health"
echo ""
echo "Monitor logs:"
echo "  aws logs tail /ecs/${ENVIRONMENT}-${APP_NAME}-backend-api --follow --region $REGION"
echo "  aws logs tail /ecs/${ENVIRONMENT}-${APP_NAME}-backend-worker --follow --region $REGION"
echo "  aws logs tail /ecs/${ENVIRONMENT}-${APP_NAME}-frontend --follow --region $REGION"

