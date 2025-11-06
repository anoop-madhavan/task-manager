# 📋 Task Manager App

A simple task manager application built with Docker containers for learning purposes. This project demonstrates a microservices architecture with three separate containers: backend API, backend worker, and frontend.

## 🏗️ Architecture

The application consists of three main services:

1. **Backend API** (`backend-api`): Express.js REST API server that handles task CRUD operations
2. **Backend Worker** (`backend-worker`): Node.js worker that polls the API queue and processes tasks
3. **Frontend** (`frontend`): React application providing the user interface

All services communicate over a Docker network, and data is stored in-memory (no database in this initial version).

## 🚀 Features

- ✅ Create, read, update, and delete tasks
- 🎯 Task priorities (Low, Medium, High)
- 📊 Task status tracking (Pending, In Progress, Completed)
- 🔄 Background worker for task processing
- 📈 Real-time statistics dashboard
- 🎨 Modern and responsive UI
- 🐳 Fully containerized with Docker

## 📋 Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)

## 🛠️ Installation & Setup

1. **Clone or navigate to the project directory:**
   ```bash
   cd task-manager
   ```

2. **Build and start all containers:**
   ```bash
   docker-compose up --build
   ```

3. **Access the application:**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:3001
   - API Health Check: http://localhost:3001/health

## 🎮 Usage

### Using the Web Interface

1. Open your browser and go to http://localhost:3000
2. Create a new task by filling out the form:
   - Enter a task title (required)
   - Add a description (optional)
   - Select priority level
3. View all tasks in the list below
4. Change task status by clicking the status buttons
5. Delete tasks using the trash icon
6. Monitor statistics at the top of the page

### API Endpoints

The backend API provides the following endpoints:

- `GET /health` - Health check
- `GET /api/tasks` - Get all tasks
- `GET /api/tasks/:id` - Get a specific task
- `POST /api/tasks` - Create a new task
- `PUT /api/tasks/:id` - Update a task
- `DELETE /api/tasks/:id` - Delete a task
- `GET /api/stats` - Get task statistics
- `GET /api/queue` - Get processing queue (for worker)

### Example API Requests

**Create a task:**
```bash
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Docker",
    "description": "Complete Docker tutorial",
    "priority": "high"
  }'
```

**Get all tasks:**
```bash
curl http://localhost:3001/api/tasks
```

**Update a task:**
```bash
curl -X PUT http://localhost:3001/api/tasks/{task-id} \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed"
  }'
```

**Delete a task:**
```bash
curl -X DELETE http://localhost:3001/api/tasks/{task-id}
```

## 🐳 Docker Services

### Backend API
- **Port:** 3001
- **Technology:** Node.js + Express
- **Responsibilities:** REST API, task management, in-memory storage

### Backend Worker
- **Technology:** Node.js
- **Responsibilities:** Polls API queue every 5 seconds, processes task events, logs activity

### Frontend
- **Port:** 3000
- **Technology:** React
- **Responsibilities:** User interface, API communication, real-time updates

## 📁 Project Structure

```
task-manager/
├── backend-api/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── backend-worker/
│   ├── Dockerfile
│   ├── package.json
│   └── worker.js
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   ├── public/
│   │   └── index.html
│   └── src/
│       ├── App.js
│       ├── App.css
│       ├── index.js
│       ├── index.css
│       └── components/
│           ├── TaskForm.js
│           ├── TaskForm.css
│           ├── TaskList.js
│           ├── TaskList.css
│           ├── TaskItem.js
│           ├── TaskItem.css
│           ├── Stats.js
│           └── Stats.css
├── docker-compose.yml
├── .gitignore
└── README.md
```

## 🔧 Development

### Running in Development Mode

The containers are configured with volume mounts for hot-reloading during development:

```bash
docker-compose up
```

### Viewing Logs

**All services:**
```bash
docker-compose logs -f
```

**Specific service:**
```bash
docker-compose logs -f backend-api
docker-compose logs -f backend-worker
docker-compose logs -f frontend
```

### Stopping the Application

```bash
docker-compose down
```

### Rebuilding Containers

```bash
docker-compose up --build
```

## 🧪 Testing the Worker

The backend worker processes task events and logs them to the console. To see it in action:

1. Start the application
2. View worker logs: `docker-compose logs -f backend-worker`
3. Create, update, or delete tasks through the UI
4. Watch the worker logs for processing activity

## 📝 Notes

- **No Database:** This version uses in-memory storage. All data is lost when containers restart.
- **Learning Purpose:** This project is designed for learning Docker, microservices, and full-stack development.
- **Auto-refresh:** The frontend automatically refreshes task data every 5 seconds.
- **Worker Polling:** The worker polls the API queue every 5 seconds for new tasks to process.

## 🚀 Future Enhancements

Potential improvements for learning:

- Add a database (PostgreSQL/MongoDB) for data persistence
- Implement WebSocket for real-time updates
- Add user authentication and authorization
- Implement task assignments and due dates
- Add email notifications via the worker
- Create task categories/tags
- Add search and filter functionality
- Implement task comments
- Add unit and integration tests
- Set up CI/CD pipeline

## 🤝 Contributing

This is a learning project. Feel free to fork and experiment!

## 📄 License

This project is open source and available for educational purposes.

## 🎓 Learning Objectives

This project helps you learn:

- Docker containerization
- Docker Compose for multi-container applications
- Building REST APIs with Express.js
- Creating background workers in Node.js
- React frontend development
- Microservices architecture
- Container networking
- API design and consumption
- Modern web development practices

---

Happy Learning! 🚀

