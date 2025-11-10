const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage
let tasks = [];
let processingQueue = [];

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'backend-api' });
});

// Get version info
app.get('/api/version', (req, res) => {
  res.json({
    service: 'backend-api',
    version: process.env.IMAGE_VERSION || 'latest',
    buildTime: process.env.BUILD_TIME || new Date().toISOString(),
    nodeVersion: process.version
  });
});

// Get all tasks
app.get('/api/tasks', (req, res) => {
  res.json(tasks);
});

// Get a single task
app.get('/api/tasks/:id', (req, res) => {
  const task = tasks.find(t => t.id === req.params.id);
  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }
  res.json(task);
});

// Create a new task
app.post('/api/tasks', (req, res) => {
  const { title, description, priority } = req.body;
  
  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }

  const newTask = {
    id: uuidv4(),
    title,
    description: description || '',
    priority: priority || 'medium',
    status: 'pending',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  tasks.push(newTask);
  
  // Add to processing queue for worker
  processingQueue.push({
    taskId: newTask.id,
    action: 'created',
    timestamp: new Date().toISOString()
  });

  res.status(201).json(newTask);
});

// Update a task
app.put('/api/tasks/:id', (req, res) => {
  const taskIndex = tasks.findIndex(t => t.id === req.params.id);
  
  if (taskIndex === -1) {
    return res.status(404).json({ error: 'Task not found' });
  }

  const { title, description, priority, status } = req.body;
  
  tasks[taskIndex] = {
    ...tasks[taskIndex],
    title: title !== undefined ? title : tasks[taskIndex].title,
    description: description !== undefined ? description : tasks[taskIndex].description,
    priority: priority !== undefined ? priority : tasks[taskIndex].priority,
    status: status !== undefined ? status : tasks[taskIndex].status,
    updatedAt: new Date().toISOString()
  };

  // Add to processing queue for worker
  processingQueue.push({
    taskId: tasks[taskIndex].id,
    action: 'updated',
    timestamp: new Date().toISOString()
  });

  res.json(tasks[taskIndex]);
});

// Delete a task
app.delete('/api/tasks/:id', (req, res) => {
  const taskIndex = tasks.findIndex(t => t.id === req.params.id);
  
  if (taskIndex === -1) {
    return res.status(404).json({ error: 'Task not found' });
  }

  const deletedTask = tasks.splice(taskIndex, 1)[0];
  
  // Add to processing queue for worker
  processingQueue.push({
    taskId: deletedTask.id,
    action: 'deleted',
    timestamp: new Date().toISOString()
  });

  res.json({ message: 'Task deleted', task: deletedTask });
});

// Get processing queue (for worker to poll)
app.get('/api/queue', (req, res) => {
  res.json(processingQueue);
});

// Clear processed items from queue
app.post('/api/queue/clear', (req, res) => {
  const { processedIds } = req.body;
  if (processedIds && Array.isArray(processedIds)) {
    processingQueue = processingQueue.filter(
      item => !processedIds.includes(item.taskId)
    );
  }
  res.json({ message: 'Queue cleared', remaining: processingQueue.length });
});

// Get stats
app.get('/api/stats', (req, res) => {
  const stats = {
    total: tasks.length,
    pending: tasks.filter(t => t.status === 'pending').length,
    inProgress: tasks.filter(t => t.status === 'in-progress').length,
    completed: tasks.filter(t => t.status === 'completed').length,
    queueSize: processingQueue.length
  };
  res.json(stats);
});

app.listen(PORT, () => {
  console.log(`Backend API running on port ${PORT}`);
});

