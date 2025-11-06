#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}
APP_NAME="task-manager"

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}WARNING: This will delete all CloudFormation stacks${NC}"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
read -p "Continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    exit 0
fi

echo -e "\n${YELLOW}Deleting stacks in reverse order...${NC}"

aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-service-frontend --region $REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-service-backend-worker --region $REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-service-backend-api --region $REGION 2>/dev/null || true

echo "Waiting for services to delete..."
sleep 30

aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-task-frontend --region $REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-task-backend-worker --region $REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-task-backend-api --region $REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-alb --region $REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-cluster --region $REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-sg --region $REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-vpc --region $REGION 2>/dev/null || true
aws cloudformation delete-stack --stack-name ${ENVIRONMENT}-${APP_NAME}-ecr --region $REGION 2>/dev/null || true

echo "Cleanup initiated. Check AWS Console for progress."

