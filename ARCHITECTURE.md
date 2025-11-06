# 🏗️ Task Manager Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Docker Network                              │
│                   (task-manager-network)                         │
│                                                                   │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │   Frontend   │      │ Backend API  │      │   Backend    │  │
│  │   (React)    │◄────►│  (Express)   │◄────►│   Worker     │  │
│  │              │      │              │      │  (Node.js)   │  │
│  │  Port: 3000  │      │  Port: 3001  │      │              │  │
│  └──────────────┘      └──────────────┘      └──────────────┘  │
│         ▲                      ▲                      ▲          │
│         │                      │                      │          │
└─────────┼──────────────────────┼──────────────────────┼──────────┘
          │                      │                      │
          │                      │                      │
    User Browser            In-Memory Storage    Polling Queue
  (localhost:3000)          (JavaScript Array)   (Every 5s)
```

## Component Details

### 1. Frontend (React Application)

**Purpose:** User interface for task management

**Technology Stack:**
- React 18
- Axios for HTTP requests
- CSS3 for styling

**Key Features:**
- Task creation form
- Task list with filtering
- Real-time statistics dashboard
- Status management (Pending, In Progress, Completed)
- Priority levels (Low, Medium, High)
- Auto-refresh every 5 seconds

**Components:**
- `App.js` - Main application container
- `TaskForm.js` - Form for creating new tasks
- `TaskList.js` - List container for all tasks
- `TaskItem.js` - Individual task card
- `Stats.js` - Statistics dashboard

**API Communication:**
```javascript
GET    /api/tasks       - Fetch all tasks
POST   /api/tasks       - Create new task
PUT    /api/tasks/:id   - Update task
DELETE /api/tasks/:id   - Delete task
GET    /api/stats       - Fetch statistics
```

### 2. Backend API (Express Server)

**Purpose:** REST API for task management and data storage

**Technology Stack:**
- Node.js
- Express.js
- CORS for cross-origin requests
- UUID for unique IDs

**Data Storage:**
- In-memory JavaScript arrays
- Two main data structures:
  - `tasks[]` - Stores all task objects
  - `processingQueue[]` - Stores events for worker processing

**Task Object Structure:**
```javascript
{
  id: "uuid-v4",
  title: "string",
  description: "string",
  priority: "low|medium|high",
  status: "pending|in-progress|completed",
  createdAt: "ISO timestamp",
  updatedAt: "ISO timestamp"
}
```

**API Endpoints:**
- `GET /health` - Health check
- `GET /api/tasks` - Get all tasks
- `GET /api/tasks/:id` - Get single task
- `POST /api/tasks` - Create task
- `PUT /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task
- `GET /api/stats` - Get statistics
- `GET /api/queue` - Get processing queue (for worker)
- `POST /api/queue/clear` - Clear processed items

### 3. Backend Worker (Node.js Service)

**Purpose:** Background processing of task events

**Technology Stack:**
- Node.js
- Axios for HTTP requests

**Responsibilities:**
- Polls API queue every 5 seconds
- Processes task creation events
- Processes task update events
- Processes task deletion events
- Logs all activity to console
- Displays statistics every 30 seconds

**Processing Flow:**
```
1. Poll /api/queue endpoint
2. For each queue item:
   - Check if already processed
   - Simulate work (1 second delay)
   - Fetch task details from API
   - Log activity
   - Mark as processed
3. Clear processed items from queue
4. Wait 5 seconds, repeat
```

**Event Types:**
- `created` - New task created
- `updated` - Task modified
- `deleted` - Task removed

## Data Flow

### Creating a Task

```
User → Frontend → Backend API → In-Memory Storage
                       ↓
                Processing Queue
                       ↓
                Backend Worker (polls)
                       ↓
                  Log Activity
```

### Updating a Task

```
User → Frontend → Backend API → Update In-Memory Storage
                       ↓
                Processing Queue
                       ↓
                Backend Worker (polls)
                       ↓
                  Log Activity
```

### Viewing Tasks

```
User → Frontend → Backend API → In-Memory Storage
         ↑              ↓
         └──────────────┘
      (Auto-refresh 5s)
```

## Docker Configuration

### Network
- Type: Bridge network
- Name: `task-manager-network`
- Allows inter-container communication

### Volumes
- Development mode uses volume mounts
- Enables hot-reloading
- Node_modules excluded from mounts

### Dependencies
```
frontend → depends_on → backend-api
backend-worker → depends_on → backend-api
```

## Communication Patterns

### Frontend ↔ Backend API
- Protocol: HTTP REST
- Format: JSON
- CORS: Enabled
- Auto-retry: No (handled by user)

### Backend Worker ↔ Backend API
- Protocol: HTTP REST
- Format: JSON
- Pattern: Polling (5s interval)
- Retry: Automatic on connection failure

## Scalability Considerations

**Current Limitations:**
- In-memory storage (data lost on restart)
- Single instance of each service
- No load balancing
- No data persistence

**Future Improvements:**
- Add database (PostgreSQL/MongoDB)
- Implement message queue (RabbitMQ/Redis)
- Add Redis for caching
- Implement WebSocket for real-time updates
- Add horizontal scaling with load balancer
- Implement health checks and auto-recovery

## Security Considerations

**Current State:**
- No authentication
- No authorization
- No input validation (basic)
- No rate limiting
- CORS enabled for all origins

**Production Recommendations:**
- Add JWT authentication
- Implement role-based access control
- Add input validation and sanitization
- Implement rate limiting
- Configure CORS for specific origins
- Add HTTPS/TLS
- Implement API versioning

## Development Workflow

1. **Start Services:**
   ```bash
   docker-compose up --build
   ```

2. **View Logs:**
   ```bash
   docker-compose logs -f [service-name]
   ```

3. **Stop Services:**
   ```bash
   docker-compose down
   ```

4. **Rebuild Single Service:**
   ```bash
   docker-compose up --build [service-name]
   ```

## Monitoring & Debugging

**Frontend:**
- Browser DevTools
- React DevTools extension
- Console logs

**Backend API:**
- Docker logs: `docker-compose logs -f backend-api`
- Health endpoint: http://localhost:3001/health
- Manual API testing with curl/Postman

**Backend Worker:**
- Docker logs: `docker-compose logs -f backend-worker`
- Activity logs show all processed events
- Statistics displayed every 30 seconds

## Performance Characteristics

**Frontend:**
- Initial load: ~2-3 seconds
- Auto-refresh: Every 5 seconds
- Responsive design for mobile/desktop

**Backend API:**
- Response time: <10ms (in-memory)
- Concurrent requests: Limited by Node.js event loop
- Memory usage: ~50MB base + task data

**Backend Worker:**
- Poll interval: 5 seconds
- Processing time: ~1 second per task
- Memory usage: ~30MB base

---

This architecture is designed for learning and can be extended with additional features and improvements!

