# 🛠️ Helpful Commands

## Quick Start

### Start the application
```bash
# Using docker-compose
docker-compose up --build

# Or using the convenience script
./start.sh
```

### Stop the application
```bash
# Using docker-compose
docker-compose down

# Or using the convenience script
./stop.sh
```

## Docker Commands

### View running containers
```bash
docker-compose ps
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend-api
docker-compose logs -f backend-worker
docker-compose logs -f frontend
```

### Rebuild specific service
```bash
docker-compose up --build backend-api
docker-compose up --build backend-worker
docker-compose up --build frontend
```

### Stop and remove all containers
```bash
docker-compose down
```

### Stop and remove containers + volumes
```bash
docker-compose down -v
```

### Restart a specific service
```bash
docker-compose restart backend-api
docker-compose restart backend-worker
docker-compose restart frontend
```

### Execute command in running container
```bash
# Access backend-api shell
docker-compose exec backend-api sh

# Access backend-worker shell
docker-compose exec backend-worker sh

# Access frontend shell
docker-compose exec frontend sh
```

### View container resource usage
```bash
docker stats
```

## API Testing Commands

### Health Check
```bash
curl http://localhost:3001/health
```

### Get all tasks
```bash
curl http://localhost:3001/api/tasks
```

### Create a task
```bash
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Docker",
    "description": "Complete Docker tutorial",
    "priority": "high"
  }'
```

### Update a task (replace {task-id} with actual ID)
```bash
curl -X PUT http://localhost:3001/api/tasks/{task-id} \
  -H "Content-Type: application/json" \
  -d '{
    "status": "in-progress"
  }'
```

### Delete a task (replace {task-id} with actual ID)
```bash
curl -X DELETE http://localhost:3001/api/tasks/{task-id}
```

### Get statistics
```bash
curl http://localhost:3001/api/stats
```

### Get processing queue
```bash
curl http://localhost:3001/api/queue
```

## Development Commands

### Install dependencies locally (optional, for IDE support)
```bash
# Backend API
cd backend-api && npm install

# Backend Worker
cd backend-worker && npm install

# Frontend
cd frontend && npm install
```

### Clean up Docker resources
```bash
# Remove all stopped containers
docker container prune

# Remove all unused images
docker image prune

# Remove all unused volumes
docker volume prune

# Remove all unused networks
docker network prune

# Remove everything (use with caution!)
docker system prune -a
```

### View Docker network details
```bash
docker network inspect task-manager_task-manager-network
```

### Check container IP addresses
```bash
docker-compose exec backend-api hostname -i
docker-compose exec backend-worker hostname -i
docker-compose exec frontend hostname -i
```

## Debugging Commands

### Check if ports are in use
```bash
# Check port 3000 (frontend)
lsof -i :3000

# Check port 3001 (backend-api)
lsof -i :3001
```

### Follow logs with timestamps
```bash
docker-compose logs -f -t backend-api
```

### View last 100 log lines
```bash
docker-compose logs --tail=100 backend-worker
```

### Inspect container details
```bash
docker-compose exec backend-api env
```

## Testing Workflow

### 1. Start fresh
```bash
docker-compose down -v
docker-compose up --build
```

### 2. Create test tasks
```bash
# Create task 1
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Task 1", "priority": "high"}'

# Create task 2
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Task 2", "priority": "medium"}'

# Create task 3
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Task 3", "priority": "low"}'
```

### 3. Watch worker process tasks
```bash
docker-compose logs -f backend-worker
```

### 4. View statistics
```bash
curl http://localhost:3001/api/stats | json_pp
```

## Troubleshooting

### Container won't start
```bash
# Check logs for errors
docker-compose logs backend-api

# Rebuild from scratch
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

### Port already in use
```bash
# Find process using port 3000
lsof -ti:3000 | xargs kill -9

# Find process using port 3001
lsof -ti:3001 | xargs kill -9
```

### Worker can't connect to API
```bash
# Check if backend-api is running
docker-compose ps backend-api

# Check network connectivity
docker-compose exec backend-worker ping backend-api

# View worker logs
docker-compose logs backend-worker
```

### Frontend can't connect to API
```bash
# Check CORS settings in backend-api
docker-compose logs backend-api

# Verify API is accessible
curl http://localhost:3001/health

# Check browser console for errors
# Open http://localhost:3000 and check DevTools
```

### Clear all data and restart
```bash
docker-compose down
docker-compose up
```

## Performance Testing

### Load test with curl
```bash
# Create 10 tasks quickly
for i in {1..10}; do
  curl -X POST http://localhost:3001/api/tasks \
    -H "Content-Type: application/json" \
    -d "{\"title\": \"Task $i\", \"priority\": \"medium\"}" &
done
wait
```

### Monitor resource usage
```bash
docker stats --no-stream
```

## Useful Aliases (add to ~/.bashrc or ~/.zshrc)

```bash
# Task Manager aliases
alias tm-start='cd ~/Documents/cursor/task-manager && docker-compose up'
alias tm-stop='cd ~/Documents/cursor/task-manager && docker-compose down'
alias tm-logs='cd ~/Documents/cursor/task-manager && docker-compose logs -f'
alias tm-rebuild='cd ~/Documents/cursor/task-manager && docker-compose up --build'
alias tm-clean='cd ~/Documents/cursor/task-manager && docker-compose down -v && docker system prune -f'
```

## URLs

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:3001
- **API Health:** http://localhost:3001/health
- **API Tasks:** http://localhost:3001/api/tasks
- **API Stats:** http://localhost:3001/api/stats

---

Keep this file handy for quick reference! 🚀

