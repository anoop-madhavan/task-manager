# Version Display Feature - Learning Guide

## 🎯 What Was Added

A version tracking system that displays Docker image versions in the UI to help you learn about:
- Image versioning and tagging
- Blue/green deployments
- Rolling updates
- Rollback scenarios

## 📊 UI Changes

The UI now displays version information in the header:

```
┌───────────────────────────────────────┐
│      📋 Task Manager                  │
│  Simple task management for learning  │
│       ┌─────────┐                     │
│       │ GLOBAL  │                     │
│       └─────────┘                     │
│                                       │
│  Frontend: v1.1.0 | Backend: v1.1.0  │ ← NEW!
└───────────────────────────────────────┘
```

## 🔧 Files Modified

### Frontend Changes:
1. **`frontend/src/App.js`**
   - Added `IMAGE_VERSION` constant from env
   - Added `backendVersion` state
   - Added `fetchBackendVersion()` function
   - Added version display UI

2. **`frontend/src/App.css`**
   - Added `.version-info` styling
   - Added `.version-item` styling
   - Added `.version-label` and `.version-value` styling

3. **`frontend/Dockerfile`**
   - Added `ARG REACT_APP_IMAGE_VERSION`
   - Added `ENV REACT_APP_IMAGE_VERSION`

### Backend Changes:
1. **`backend-api/server.js`**
   - Added `/api/version` endpoint
   - Returns version, buildTime, nodeVersion

2. **`backend-api/Dockerfile`**
   - Added `ARG IMAGE_VERSION` and `BUILD_TIME`
   - Added corresponding ENV variables

### Build Scripts:
1. **`build-and-push-versioned.sh`** (NEW)
   - Builds images with version and build time
   - Tags images with version number
   - Pushes both versioned and latest tags

## 🚀 How to Use

### 1. Build Versioned Images

```bash
cd /Users/anoop/Documents/cursor/task-manager

# Make script executable
chmod +x build-and-push-versioned.sh

# Build with auto-generated version (timestamp)
./build-and-push-versioned.sh

# Or build with specific version
./build-and-push-versioned.sh v1.1.0

# Or build with version and specify region
./build-and-push-versioned.sh v1.2.0 us-east-1
```

### 2. Deploy New Version

After building, force ECS services to redeploy:

```bash
# For global instance
aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service global-frontend \
  --force-new-deployment \
  --region us-east-1

aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service global-backend-api \
  --force-new-deployment \
  --region us-east-1

# For customer1 instance
aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service customer1-frontend \
  --force-new-deployment \
  --region us-east-1

aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service customer1-backend-api \
  --force-new-deployment \
  --region us-east-1
```

### 3. Verify Version in UI

Open your browser:
- **Global**: https://freeinterestcal.com
- **Customer 1**: https://customer1.freeinterestcal.com

You should see version info at the bottom of the header!

## 📚 Learning Scenarios

### Scenario 1: Blue/Green Deployment

```bash
# Build new version
./build-and-push-versioned.sh v1.2.0

# Deploy to customer1 first (canary)
aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service customer1-frontend \
  --force-new-deployment

# Wait and verify customer1 works
# Then deploy to global
aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service global-frontend \
  --force-new-deployment
```

### Scenario 2: Rollback

```bash
# If new version has issues, redeploy old version
./build-and-push-versioned.sh v1.0.0

# Force redeployment
aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service global-frontend \
  --force-new-deployment
```

### Scenario 3: Different Versions Per Customer

```bash
# Customer1 gets latest features
# Tag customer1 with v1.2.0
aws ecs update-service \
  --cluster dev-task-manager-cluster \
  --service customer1-frontend \
  --force-new-deployment

# Global stays on stable v1.1.0
# (don't update global)
```

Now you can see in the UI:
- Global: v1.1.0
- Customer1: v1.2.0

## 🎓 Learning Benefits

1. **Visual Feedback**: Instantly see which version is deployed
2. **Deployment Tracking**: Know when updates roll out
3. **Troubleshooting**: Quickly identify version mismatches
4. **A/B Testing**: Run different versions for different customers
5. **Rollback Verification**: Confirm old version is restored

## 🔍 API Endpoints

### Get Backend Version
```bash
curl https://freeinterestcal.com/api/version
```

Response:
```json
{
  "service": "backend-api",
  "version": "v1.1.0",
  "buildTime": "2025-11-10T13:30:00Z",
  "nodeVersion": "v18.x.x"
}
```

## 📝 Version Naming Convention

Recommended format: `v{major}.{minor}.{patch}`

Examples:
- `v1.0.0` - Initial release
- `v1.1.0` - New features (minor)
- `v1.1.1` - Bug fixes (patch)
- `v2.0.0` - Breaking changes (major)

Or use timestamps:
- `v20251110-1330` - Date + time
- Auto-generated by script if no version provided

## 🎨 UI Styling

The version info:
- Semi-transparent background
- Monospace font for version numbers
- Purple accent color matching instance badge
- Responsive layout

## 🔄 Next Steps

To deploy this feature:

1. **Build new images**:
   ```bash
   cd /Users/anoop/Documents/cursor/task-manager
   chmod +x build-and-push-versioned.sh
   ./build-and-push-versioned.sh v1.1.0
   ```

2. **Force services to redeploy**:
   ```bash
   # Redeploy all services to pick up new images
   for service in global-frontend global-backend-api customer1-frontend customer1-backend-api; do
     aws ecs update-service \
       --cluster dev-task-manager-cluster \
       --service $service \
       --force-new-deployment \
       --region us-east-1
   done
   ```

3. **Wait 2-3 minutes** for deployment

4. **Check UI** - Version info should appear!

## 💡 Pro Tips

- Always build with version tags for production
- Keep `latest` tag for development
- Use semantic versioning for clarity
- Document what changed in each version
- Test new versions on one customer first before rolling out to all

Happy learning! 🚀

