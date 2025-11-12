# Multi-Customer Deployment Guide Index

This directory contains guides for deploying a multi-customer (multi-tenant) task manager application on AWS.

## Available Guides

### 1. Automated Deployment (Production)
**File**: [README.md](./README.md)  
**Tags**: `cloudformation`, `automated`, `production`, `multi-customer`  
**Method**: CloudFormation templates via AWS CLI  
**Difficulty**: Beginner  
**Time**: 30-45 minutes  
**Best For**: Production deployments, CI/CD pipelines

**What it does**:
- Deploys all infrastructure via CloudFormation
- Fully automated with scripts
- Infrastructure as Code (IaC)
- Easy to version control and replicate

---

### 2. Manual GUI Setup (Learning)
**File**: [MANUAL_GUI_SETUP.md](./MANUAL_GUI_SETUP.md)  
**Tags**: `multi-customer-gui`, `aws-console`, `manual-setup`, `learning-guide`  
**Method**: AWS Console GUI (with some CloudFormation)  
**Difficulty**: Intermediate  
**Time**: 2-3 hours  
**Best For**: Learning AWS services, understanding architecture

**What it does**:
- CloudFormation: VPC, ECR, ECS Cluster, IAM, Security Groups
- Manual GUI: ALB, Target Groups, Listener Rules, Task Definitions, Services, DNS
- Step-by-step screenshots-ready instructions
- Detailed explanations of each component

---

## Quick Comparison

| Feature | Automated (README.md) | Manual GUI (MANUAL_GUI_SETUP.md) |
|---------|----------------------|----------------------------------|
| **Deployment Method** | CloudFormation CLI | AWS Console GUI |
| **Time Required** | 30-45 minutes | 2-3 hours |
| **Difficulty** | Beginner | Intermediate |
| **Learning Value** | Low | High |
| **Production Ready** | ✅ Yes | ❌ No (educational only) |
| **Reproducible** | ✅ Yes | ⚠️ Manual steps |
| **Version Control** | ✅ Yes | ❌ No |
| **Best For** | Production | Learning |

---

## Architecture Overview

Both guides deploy the same architecture:

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

---

## Shared Infrastructure (Both Guides)

Deployed once, shared by all customers:

| Resource | Quantity | Purpose |
|----------|----------|---------|
| VPC | 1 | Network isolation |
| Public Subnets | 2 | ALB placement (multi-AZ) |
| Private Subnets | 2 | ECS tasks (multi-AZ) |
| NAT Gateway | 1 | Outbound internet for private subnets |
| Internet Gateway | 1 | Inbound internet access |
| Security Groups | 4 | ALB, Backend API, Worker, Frontend |
| ECS Cluster | 1 | Container orchestration |
| ECR Repository | 1 | Docker image storage |
| IAM Roles | 2 | Task Execution, Task Runtime |
| Application Load Balancer | 1 | Traffic routing |

**Cost**: ~$81/month

---

## Per-Customer Resources (Both Guides)

Deployed for each customer (isolated):

| Resource | Quantity | Purpose |
|----------|----------|---------|
| CloudWatch Log Groups | 3 | Backend API, Worker, Frontend logs |
| Target Groups | 2 | Backend API, Frontend (Worker has none) |
| ALB Listener Rules | 2 | Host-based routing |
| ECS Task Definitions | 3 | Container specifications |
| ECS Services | 3 | Service management |
| Route 53 DNS Record | 1 | Domain → ALB mapping |

**Cost**: ~$38/month per customer

---

## Which Guide Should I Use?

### Use Automated (README.md) if you want to:
- ✅ Deploy to production
- ✅ Automate deployments
- ✅ Use CI/CD pipelines
- ✅ Version control infrastructure
- ✅ Quickly spin up environments
- ✅ Minimize human error

### Use Manual GUI (MANUAL_GUI_SETUP.md) if you want to:
- 📚 Learn AWS services hands-on
- 📚 Understand how components connect
- 📚 Prepare for AWS certifications
- 📚 Debug issues more effectively
- 📚 Customize beyond templates
- 📚 See the AWS Console workflow

---

## Getting Started

### For Production (Automated):
```bash
cd cloudformation/multi-customer
# Follow README.md
```

### For Learning (Manual GUI):
```bash
cd cloudformation/multi-customer
# Follow MANUAL_GUI_SETUP.md
```

---

## Tags Reference

Search for these tags to find specific content:

| Tag | Description | Files |
|-----|-------------|-------|
| `multi-customer` | Multi-tenant architecture | README.md, MANUAL_GUI_SETUP.md |
| `multi-customer-gui` | GUI-based setup | MANUAL_GUI_SETUP.md |
| `cloudformation` | CloudFormation templates | README.md, *.yaml |
| `automated` | Automated deployment | README.md |
| `manual-setup` | Manual setup steps | MANUAL_GUI_SETUP.md |
| `learning-guide` | Educational content | MANUAL_GUI_SETUP.md |
| `aws-console` | AWS Console GUI | MANUAL_GUI_SETUP.md |
| `production` | Production-ready | README.md |
| `ecs` | ECS/Fargate | Both |
| `alb` | Application Load Balancer | Both |
| `multi-tenant` | Multi-tenant patterns | Both |

---

## Support

- **Issues**: Check troubleshooting sections in each guide
- **Questions**: Review architecture diagrams and explanations
- **Customization**: Modify CloudFormation templates or GUI steps as needed

---

**Last Updated**: 2025-11-12  
**Maintained By**: Task Manager Project Team

