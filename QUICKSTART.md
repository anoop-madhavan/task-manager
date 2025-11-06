# ⚡ Quick Start Guide

## 🚀 Get Started in 3 Steps

### 1️⃣ Start the Application
```bash
docker-compose up --build
```

### 2️⃣ Open Your Browser
```
http://localhost:3000
```

### 3️⃣ Start Creating Tasks!
- Fill out the form
- Click "Create Task"
- Watch the worker process it in real-time

---

## 📊 What You'll See

### Frontend (Port 3000)
- Beautiful task management interface
- Real-time statistics
- Create, update, and delete tasks
- Priority levels and status tracking

### Backend API (Port 3001)
- REST API handling all operations
- In-memory task storage
- Processing queue for worker

### Backend Worker (Background)
- Polls API every 5 seconds
- Processes task events
- Logs activity to console

---

## 🔍 View Worker Activity

Open a new terminal and run:
```bash
docker-compose logs -f backend-worker
```

Now create/update/delete tasks in the UI and watch the worker process them!

---

## 🛑 Stop the Application

```bash
docker-compose down
```

Or press `Ctrl+C` in the terminal where it's running.

---

## 📚 Learn More

- **README.md** - Complete documentation
- **ARCHITECTURE.md** - System design and architecture
- **COMMANDS.md** - All useful commands and API examples

---

## ✅ Verify Everything Works

### Test the API
```bash
# Health check
curl http://localhost:3001/health

# Create a task
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "My First Task", "priority": "high"}'

# Get all tasks
curl http://localhost:3001/api/tasks
```

### Check the Frontend
1. Open http://localhost:3000
2. You should see the Task Manager interface
3. Create a task using the form
4. Watch it appear in the list below

### Monitor the Worker
```bash
docker-compose logs -f backend-worker
```
You should see:
- "Worker started successfully!"
- Polling messages every 5 seconds
- Task processing logs when you create/update tasks

---

## 🎓 Learning Path

1. **Start Simple**: Create and manage tasks through the UI
2. **Explore API**: Test endpoints with curl
3. **Watch Worker**: Monitor background processing
4. **Read Code**: Understand how each service works
5. **Modify**: Try adding new features!

---

## 🐛 Troubleshooting

### Port already in use?
```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Kill process on port 3001
lsof -ti:3001 | xargs kill -9
```

### Container won't start?
```bash
# Clean rebuild
docker-compose down -v
docker-compose up --build
```

### Need help?
Check **COMMANDS.md** for detailed troubleshooting steps.

---

## 🎯 Key Features to Try

- ✅ Create tasks with different priorities
- ✅ Change task status (Pending → In Progress → Completed)
- ✅ Delete tasks
- ✅ Watch statistics update in real-time
- ✅ Monitor worker logs
- ✅ Test API endpoints with curl

---

**Happy Learning! 🚀**

*This is a learning project - feel free to experiment and break things!*

