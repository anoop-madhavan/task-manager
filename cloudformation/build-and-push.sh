#!/bin/bash
set -e

VERSION=${1:-latest}
REGION=${2:-us-east-1}
APP_NAME="task-manager"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Building and pushing Task Manager images...${NC}"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "ECR Registry: $ECR_REGISTRY"
echo "Version: $VERSION"

# Login to ECR
echo -e "\n${YELLOW}Logging in to ECR...${NC}"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push backend-api
echo -e "\n${YELLOW}Building backend-api...${NC}"
docker buildx build --platform linux/amd64 -t ${APP_NAME}-backend-api:${VERSION} ./backend-api
docker tag ${APP_NAME}-backend-api:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:backend-api-${VERSION}
docker tag ${APP_NAME}-backend-api:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:backend-api-latest
docker push ${ECR_REGISTRY}/${APP_NAME}:backend-api-${VERSION}
docker push ${ECR_REGISTRY}/${APP_NAME}:backend-api-latest
echo -e "${GREEN}✓ backend-api pushed${NC}"

# Build and push backend-worker
echo -e "\n${YELLOW}Building backend-worker...${NC}"
docker buildx build --platform linux/amd64 -t ${APP_NAME}-backend-worker:${VERSION} ./backend-worker
docker tag ${APP_NAME}-backend-worker:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:backend-worker-${VERSION}
docker tag ${APP_NAME}-backend-worker:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:backend-worker-latest
docker push ${ECR_REGISTRY}/${APP_NAME}:backend-worker-${VERSION}
docker push ${ECR_REGISTRY}/${APP_NAME}:backend-worker-latest
echo -e "${GREEN}✓ backend-worker pushed${NC}"

# Build and push frontend
echo -e "\n${YELLOW}Building frontend...${NC}"
docker buildx build --platform linux/amd64 -t ${APP_NAME}-frontend:${VERSION} ./frontend
docker tag ${APP_NAME}-frontend:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:frontend-${VERSION}
docker tag ${APP_NAME}-frontend:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:frontend-latest
docker push ${ECR_REGISTRY}/${APP_NAME}:frontend-${VERSION}
docker push ${ECR_REGISTRY}/${APP_NAME}:frontend-latest
echo -e "${GREEN}✓ frontend pushed${NC}"

echo -e "\n${GREEN}All images built and pushed successfully!${NC}"
echo "Images:"
echo "  ${ECR_REGISTRY}/${APP_NAME}:backend-api-${VERSION}"
echo "  ${ECR_REGISTRY}/${APP_NAME}:backend-worker-${VERSION}"
echo "  ${ECR_REGISTRY}/${APP_NAME}:frontend-${VERSION}"

