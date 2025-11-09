# HTTPS Setup with Custom Domain

Guide to configure `freeinterestcal.com` with HTTPS for your Task Manager ALB.

## Prerequisites

- Domain registered in Route 53: `freeinterestcal.com`
- ALB deployed and running
- AWS CLI configured

## Step 1: Request SSL/TLS Certificate (ACM)

### 1.1 Request Certificate

```bash
# Set your domain
export DOMAIN_NAME="freeinterestcal.com"
export REGION="us-east-1"

# Request certificate
aws acm request-certificate \
  --domain-name $DOMAIN_NAME \
  --subject-alternative-names "www.$DOMAIN_NAME" \
  --validation-method DNS \
  --region $REGION
```

**Output:** You'll get a Certificate ARN like:
```
arn:aws:acm:us-east-1:123456789012:certificate/abc123...
```

Save this ARN:
```bash
export CERTIFICATE_ARN="arn:aws:acm:us-east-1:123456789012:certificate/abc123..."
```

### 1.2 Get Validation Records

```bash
aws acm describe-certificate \
  --certificate-arn $CERTIFICATE_ARN \
  --region $REGION \
  --query 'Certificate.DomainValidationOptions[*].[DomainName,ResourceRecord]' \
  --output table
```

**Output will show:**
```
Name: _abc123.freeinterestcal.com
Type: CNAME
Value: _xyz789.acm-validations.aws.
```

### 1.3 Add Validation Records to Route 53

**Option A: Using AWS Console**
1. Go to Route 53 → Hosted Zones
2. Click on `freeinterestcal.com`
3. Click "Create record"
4. Record name: `_abc123` (from validation output)
5. Record type: `CNAME`
6. Value: `_xyz789.acm-validations.aws.` (from validation output)
7. Click "Create records"

**Option B: Using AWS CLI**

First, get your hosted zone ID:
```bash
export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name $DOMAIN_NAME \
  --query 'HostedZones[0].Id' \
  --output text | cut -d'/' -f3)

echo "Hosted Zone ID: $HOSTED_ZONE_ID"
```

Get validation details:
```bash
aws acm describe-certificate \
  --certificate-arn $CERTIFICATE_ARN \
  --region $REGION \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
  --output json
```

Create the validation record (replace values from output above):
```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "_abc123.freeinterestcal.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "_xyz789.acm-validations.aws."}]
      }
    }]
  }'
```

### 1.4 Wait for Certificate Validation

```bash
# This may take 5-30 minutes
aws acm wait certificate-validated \
  --certificate-arn $CERTIFICATE_ARN \
  --region $REGION

echo "Certificate validated!"
```

Or check status:
```bash
aws acm describe-certificate \
  --certificate-arn $CERTIFICATE_ARN \
  --region $REGION \
  --query 'Certificate.Status' \
  --output text
```

---

## Step 2: Add HTTPS Listener to ALB

### 2.1 Get ALB ARN

```bash
export ENVIRONMENT=dev
export APP_NAME=task-manager

export ALB_ARN=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-alb \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' \
  --output text)

echo "ALB ARN: $ALB_ARN"
```

### 2.2 Get Target Group ARNs

```bash
export FRONTEND_TG_ARN=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-alb \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`FrontendTargetGroupArn`].OutputValue' \
  --output text)

export BACKEND_TG_ARN=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-alb \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`BackendAPITargetGroupArn`].OutputValue' \
  --output text)

echo "Frontend TG: $FRONTEND_TG_ARN"
echo "Backend TG: $BACKEND_TG_ARN"
```

### 2.3 Create HTTPS Listener (Port 443)

```bash
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$CERTIFICATE_ARN \
  --default-actions Type=forward,TargetGroupArn=$FRONTEND_TG_ARN \
  --region $REGION
```

**Output:** You'll get a Listener ARN. Save it:
```bash
export HTTPS_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/..."
```

### 2.4 Add Backend API Rule to HTTPS Listener

```bash
aws elbv2 create-rule \
  --listener-arn $HTTPS_LISTENER_ARN \
  --priority 1 \
  --conditions Field=path-pattern,Values='/api/*' Field=path-pattern,Values='/health' \
  --actions Type=forward,TargetGroupArn=$BACKEND_TG_ARN \
  --region $REGION
```

### 2.5 Add HTTP to HTTPS Redirect (Optional but Recommended)

Get HTTP Listener ARN:
```bash
export HTTP_LISTENER_ARN=$(aws elbv2 describe-listeners \
  --load-balancer-arn $ALB_ARN \
  --region $REGION \
  --query 'Listeners[?Port==`80`].ListenerArn' \
  --output text)

echo "HTTP Listener ARN: $HTTP_LISTENER_ARN"
```

Modify HTTP listener to redirect to HTTPS:
```bash
aws elbv2 modify-listener \
  --listener-arn $HTTP_LISTENER_ARN \
  --default-actions Type=redirect,RedirectConfig="{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}" \
  --region $REGION
```

---

## Step 3: Create Route 53 DNS Records

### 3.1 Get ALB DNS Name

```bash
export ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT}-${APP_NAME}-alb \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

echo "ALB DNS: $ALB_DNS"
```

### 3.2 Get ALB Hosted Zone ID

```bash
export ALB_HOSTED_ZONE_ID=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --region $REGION \
  --query 'LoadBalancers[0].CanonicalHostedZoneId' \
  --output text)

echo "ALB Hosted Zone ID: $ALB_HOSTED_ZONE_ID"
```

### 3.3 Create A Record for Root Domain

```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "freeinterestcal.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "'$ALB_HOSTED_ZONE_ID'",
          "DNSName": "'$ALB_DNS'",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'
```

### 3.4 Create A Record for www Subdomain

```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.freeinterestcal.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "'$ALB_HOSTED_ZONE_ID'",
          "DNSName": "'$ALB_DNS'",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'
```

---

## Step 4: Update Frontend Environment Variable

Your frontend needs to know the API URL. Update the task definition:

### 4.1 Get Current Task Definition

```bash
aws ecs describe-task-definition \
  --task-definition ${ENVIRONMENT}-${APP_NAME}-frontend \
  --region $REGION \
  --query 'taskDefinition' > frontend-task-def.json
```

### 4.2 Update REACT_APP_API_URL

Edit `frontend-task-def.json` and change:
```json
"environment": [
  {
    "name": "REACT_APP_API_URL",
    "value": "https://freeinterestcal.com"
  }
]
```

### 4.3 Register New Task Definition

```bash
# Remove unnecessary fields
jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)' \
  frontend-task-def.json > frontend-task-def-new.json

# Register new revision
aws ecs register-task-definition \
  --cli-input-json file://frontend-task-def-new.json \
  --region $REGION
```

### 4.4 Update Service

```bash
aws ecs update-service \
  --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service ${ENVIRONMENT}-${APP_NAME}-frontend \
  --force-new-deployment \
  --region $REGION
```

---

## Step 5: Verify Setup

### 5.1 Test DNS Resolution

```bash
# Wait a few minutes for DNS propagation
dig freeinterestcal.com
dig www.freeinterestcal.com

# Should show ALB IP addresses
```

### 5.2 Test HTTPS

```bash
# Test root domain
curl -I https://freeinterestcal.com

# Test www
curl -I https://www.freeinterestcal.com

# Test API
curl https://freeinterestcal.com/health

# Test HTTP redirect
curl -I http://freeinterestcal.com
# Should return 301 redirect to https://
```

### 5.3 Test in Browser

1. Open: https://freeinterestcal.com
2. Check for 🔒 (secure lock icon)
3. Verify certificate is valid
4. Test creating a task

---

## Troubleshooting

### Certificate Not Validating

```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn $CERTIFICATE_ARN \
  --region $REGION

# Verify CNAME record exists in Route 53
aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query 'ResourceRecordSets[?Type==`CNAME`]'
```

### DNS Not Resolving

```bash
# Check Route 53 records
aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID

# Check nameservers
dig NS freeinterestcal.com
```

### HTTPS Not Working

```bash
# Check HTTPS listener exists
aws elbv2 describe-listeners \
  --load-balancer-arn $ALB_ARN \
  --region $REGION

# Check certificate is attached
aws elbv2 describe-listener-certificates \
  --listener-arn $HTTPS_LISTENER_ARN \
  --region $REGION
```

### Mixed Content Errors

If you see mixed content warnings:
1. Ensure all API calls use `https://` not `http://`
2. Check browser console for blocked resources
3. Update `REACT_APP_API_URL` to use HTTPS

---

## Summary of What You Created

```
Internet
    ↓
Route 53: freeinterestcal.com → ALB
    ↓
ALB:443 (HTTPS with ACM Certificate)
    ↓
    ├─→ /api/* → Backend API (3001)
    └─→ /* → Frontend (3000)

HTTP:80 → Redirects to HTTPS:443
```

---

## Security Best Practices

### 1. Enable Security Headers

Add to ALB response headers:
- `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`

### 2. Use Strong SSL Policy

```bash
aws elbv2 modify-listener \
  --listener-arn $HTTPS_LISTENER_ARN \
  --ssl-policy ELBSecurityPolicy-TLS-1-2-2017-01 \
  --region $REGION
```

### 3. Enable Access Logs

```bash
aws elbv2 modify-load-balancer-attributes \
  --load-balancer-arn $ALB_ARN \
  --attributes Key=access_logs.s3.enabled,Value=true \
              Key=access_logs.s3.bucket,Value=my-alb-logs \
  --region $REGION
```

---

## Cost Impact

**Additional Costs:**
- ACM Certificate: **FREE** ✅
- Route 53 Hosted Zone: **$0.50/month**
- Route 53 Queries: **$0.40 per million queries**
- No additional ALB cost for HTTPS

**Total Additional Cost:** ~$1-2/month

---

## Quick Reference Commands

```bash
# Check certificate status
aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region $REGION

# Check DNS records
aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID

# Check ALB listeners
aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --region $REGION

# Force service update
aws ecs update-service --cluster ${ENVIRONMENT}-${APP_NAME}-cluster \
  --service ${ENVIRONMENT}-${APP_NAME}-frontend --force-new-deployment --region $REGION

# Test HTTPS
curl -I https://freeinterestcal.com
```

---

Your domain will be accessible at:
- **https://freeinterestcal.com** ✅
- **https://www.freeinterestcal.com** ✅
- **http://freeinterestcal.com** → Redirects to HTTPS ✅

