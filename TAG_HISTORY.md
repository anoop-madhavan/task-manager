# Git Tag History

This document tracks all Git tags in the project with proper versioning.

## Current Tags (Versioned)

### v1.0-initial-docker
**Date**: Initial release  
**Description**: Basic Docker Compose setup  
**Features**:
- Frontend (React)
- Backend API (Node.js)
- Backend Worker
- Local development with Docker Compose

**Original Tag**: `inital-version-docker`

---

### v1.1-cloudformation-ecs
**Date**: CloudFormation implementation  
**Description**: Working CloudFormation templates for ECS deployment  
**Features**:
- VPC with public/private subnets
- Security Groups
- IAM Roles
- ECS Cluster
- Task Definitions
- ECS Services
- Application Load Balancer
- Target Groups

**Original Tag**: `working-cloudformation-ecs-deployment`

---

### v1.2-multi-customer-ecs
**Date**: Multi-tenant architecture  
**Description**: Multi-customer ECS architecture with shared infrastructure  
**Features**:
- Shared infrastructure (VPC, ECS Cluster, ALB)
- Per-customer isolation (services, target groups, DNS)
- Host-based routing via ALB listener rules
- Unique domains per customer
- CloudWatch log groups per customer
- Automated CloudFormation deployment

**Original Tag**: `multi-customer-unique-domain-ecs`

**Key Files**:
- `cloudformation/multi-customer/*.yaml`
- `cloudformation/multi-customer/README.md`

---

### v1.3-multi-customer-gui
**Date**: 2025-11-12  
**Description**: Manual GUI setup guide for learning purposes  
**Features**:
- Hybrid approach: CloudFormation + Manual GUI
- CloudFormation deploys: VPC, ECR, ECS, IAM, Security Groups
- Manual GUI setup: ALB, Target Groups, Listener Rules, Task Definitions, Services, DNS
- Step-by-step AWS Console instructions
- Educational guide with detailed explanations
- Troubleshooting section
- Cost estimates
- Supports multiple customers

**Key Files**:
- `cloudformation/multi-customer/MANUAL_GUI_SETUP.md` (NEW)
- `cloudformation/multi-customer/GUIDE_INDEX.md` (NEW)
- `cloudformation/multi-customer/.tags` (NEW)

**Tags**: `multi-customer-gui`, `aws-console`, `manual-setup`, `learning-guide`

---

## Legacy Tags (Unversioned)

These tags exist for historical reference but should use the versioned equivalents:

| Legacy Tag | Versioned Equivalent | Status |
|------------|---------------------|---------|
| `inital-version-docker` | `v1.0-initial-docker` | ✅ Superseded |
| `working-cloudformation-ecs-deployment` | `v1.1-cloudformation-ecs` | ✅ Superseded |
| `multi-customer-unique-domain-ecs` | `v1.2-multi-customer-ecs` | ✅ Superseded |

---

## Version Numbering Scheme

We use semantic versioning with descriptive suffixes:

```
v{MAJOR}.{MINOR}-{DESCRIPTION}

Examples:
- v1.0-initial-docker
- v1.1-cloudformation-ecs
- v1.2-multi-customer-ecs
- v1.3-multi-customer-gui
```

### When to Increment:

- **MAJOR** (v1 → v2): Breaking changes, complete architecture redesign
- **MINOR** (v1.0 → v1.1): New features, significant additions
- **DESCRIPTION**: Brief identifier of what the version introduces

---

## Tag Timeline

```
v1.0-initial-docker (Docker Compose)
    ↓
v1.1-cloudformation-ecs (CloudFormation automation)
    ↓
v1.2-multi-customer-ecs (Multi-tenant architecture)
    ↓
v1.3-multi-customer-gui (Learning-focused GUI guide)
    ↓
v1.4-??? (Future)
```

---

## Future Versions (Planned)

### v1.4-ci-cd-pipeline
- GitHub Actions / GitLab CI
- Automated testing
- Automated deployments
- Blue-green deployments

### v1.5-monitoring-alerts
- CloudWatch dashboards
- SNS alerts
- Custom metrics
- Performance monitoring

### v1.6-database-integration
- RDS or DynamoDB
- Data persistence
- Database migrations
- Backup strategies

### v2.0-kubernetes
- EKS deployment
- Helm charts
- Kubernetes manifests
- Service mesh (Istio/Linkerd)

---

## How to Use Tags

### List all tags:
```bash
git tag -l --sort=version:refname
```

### View tag details:
```bash
git show v1.3-multi-customer-gui
```

### Checkout a specific version:
```bash
git checkout v1.3-multi-customer-gui
```

### Compare versions:
```bash
git diff v1.2-multi-customer-ecs v1.3-multi-customer-gui
```

### Push tags to remote:
```bash
# Push specific tag
git push origin v1.3-multi-customer-gui

# Push all tags
git push origin --tags
```

---

## Tag Naming Convention

**Format**: `v{MAJOR}.{MINOR}-{kebab-case-description}`

**Rules**:
1. Always start with `v`
2. Use semantic versioning (MAJOR.MINOR)
3. Use kebab-case for description
4. Keep description concise but meaningful
5. Description should indicate the main feature/change

**Good Examples**:
- ✅ `v1.3-multi-customer-gui`
- ✅ `v1.4-ci-cd-pipeline`
- ✅ `v2.0-kubernetes-migration`

**Bad Examples**:
- ❌ `multi-customer-gui` (no version)
- ❌ `v1.3` (no description)
- ❌ `v1.3_multi_customer` (use kebab-case)
- ❌ `v1.3-added-new-gui-setup-guide` (too verbose)

---

## Tagging Checklist

Before creating a new tag:

- [ ] All changes committed
- [ ] Tests passing (if applicable)
- [ ] Documentation updated
- [ ] Version number follows convention
- [ ] Tag message is descriptive
- [ ] Related files are documented

### Create Tag Command:
```bash
git tag -a v1.X-description -m "vX.Y - Title

Detailed description of changes:
- Feature 1
- Feature 2
- Feature 3

Key files:
- path/to/file1
- path/to/file2

Tags: tag1, tag2, tag3"
```

---

## Deployment Guides by Version

| Version | Guide | Method | Best For |
|---------|-------|--------|----------|
| v1.0 | Docker Compose | Local | Development |
| v1.1 | CloudFormation | Automated | Production |
| v1.2 | Multi-Customer CF | Automated | Multi-tenant Production |
| v1.3 | Multi-Customer GUI | Hybrid | Learning |

---

**Last Updated**: 2025-11-12  
**Current Version**: v1.3-multi-customer-gui  
**Next Version**: TBD

