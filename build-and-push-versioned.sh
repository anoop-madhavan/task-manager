#!/bin/bash
set -e

# Usage: ./build-and-push-versioned.sh v1.0.0
VERSION=${1:-v$(date +%Y%m%d-%H%M%S)}
REGION=${2:-us-east-1}
APP_NAME="task-manager"
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Building Versioned Task Manager Images${NC}"
echo -e "${GREEN}=========================================${NC}"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo -e "${BLUE}Configuration:${NC}"
echo "  ECR Registry: $ECR_REGISTRY"
echo "  Version:      $VERSION"
echo "  Build Time:   $BUILD_TIME"
echo ""

# Login to ECR
echo -e "${YELLOW}Logging in to ECR...${NC}"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push backend-api
echo -e "\n${YELLOW}Building backend-api with version info...${NC}"
docker build \
  --platform linux/amd64 \
  --build-arg IMAGE_VERSION=$VERSION \
  --build-arg BUILD_TIME="$BUILD_TIME" \
  -t ${APP_NAME}-backend-api:${VERSION} \
  ./backend-api

docker tag ${APP_NAME}-backend-api:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:backend-api-${VERSION}
docker tag ${APP_NAME}-backend-api:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:backend-api-latest
docker push ${ECR_REGISTRY}/${APP_NAME}:backend-api-${VERSION}
docker push ${ECR_REGISTRY}/${APP_NAME}:backend-api-latest
echo -e "${GREEN}✓ backend-api pushed${NC}"

# Build and push backend-worker
echo -e "\n${YELLOW}Building backend-worker with version info...${NC}"
docker build \
  --platform linux/amd64 \
  --build-arg IMAGE_VERSION=$VERSION \
  --build-arg BUILD_TIME="$BUILD_TIME" \
  -t ${APP_NAME}-backend-worker:${VERSION} \
  ./backend-worker

docker tag ${APP_NAME}-backend-worker:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:backend-worker-${VERSION}
docker tag ${APP_NAME}-backend-worker:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:backend-worker-latest
docker push ${ECR_REGISTRY}/${APP_NAME}:backend-worker-${VERSION}
docker push ${ECR_REGISTRY}/${APP_NAME}:backend-worker-latest
echo -e "${GREEN}✓ backend-worker pushed${NC}"

# Build and push frontend
echo -e "\n${YELLOW}Building frontend with version info...${NC}"
docker build \
  --platform linux/amd64 \
  --build-arg REACT_APP_IMAGE_VERSION=$VERSION \
  --build-arg BUILD_TIME="$BUILD_TIME" \
  -t ${APP_NAME}-frontend:${VERSION} \
  ./frontend

docker tag ${APP_NAME}-frontend:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:frontend-${VERSION}
docker tag ${APP_NAME}-frontend:${VERSION} ${ECR_REGISTRY}/${APP_NAME}:frontend-latest
docker push ${ECR_REGISTRY}/${APP_NAME}:frontend-${VERSION}
docker push ${ECR_REGISTRY}/${APP_NAME}:frontend-latest
echo -e "${GREEN}✓ frontend pushed${NC}"

echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ All images built and pushed!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "${BLUE}Images tagged as:${NC}"
echo "  ${ECR_REGISTRY}/${APP_NAME}:backend-api-${VERSION}"
echo "  ${ECR_REGISTRY}/${APP_NAME}:backend-worker-${VERSION}"
echo "  ${ECR_REGISTRY}/${APP_NAME}:frontend-${VERSION}"
echo ""
echo -e "${YELLOW}To deploy this version, update your CloudFormation stacks with:${NC}"
echo "  IMAGE_VERSION=$VERSION"

