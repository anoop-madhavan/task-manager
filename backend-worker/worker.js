const axios = require('axios');

const API_URL = process.env.API_URL || 'http://backend-api:3001';
const POLL_INTERVAL = 5000; // Poll every 5 seconds

console.log('Backend Worker starting...');
console.log(`API URL: ${API_URL}`);

// Store processed task IDs to avoid reprocessing
let processedTaskIds = new Set();

async function pollQueue() {
  try {
    // Fetch the queue from the API
    const response = await axios.get(`${API_URL}/api/queue`);
    const queue = response.data;

    if (queue.length === 0) {
      console.log(`[${new Date().toISOString()}] Queue is empty`);
      return;
    }

    console.log(`[${new Date().toISOString()}] Processing ${queue.length} items from queue`);

    // Process each item in the queue
    for (const item of queue) {
      if (!processedTaskIds.has(item.taskId)) {
        await processTask(item);
        processedTaskIds.add(item.taskId);
      }
    }

    // Clear processed items from the API queue
    const processedIds = Array.from(processedTaskIds);
    if (processedIds.length > 0) {
      await axios.post(`${API_URL}/api/queue/clear`, {
        processedIds: processedIds
      });
      
      // Keep only recent processed IDs (last 100) to prevent memory issues
      if (processedTaskIds.size > 100) {
        const idsArray = Array.from(processedTaskIds);
        processedTaskIds = new Set(idsArray.slice(-100));
      }
    }

  } catch (error) {
    if (error.code === 'ECONNREFUSED') {
      console.error(`[${new Date().toISOString()}] Cannot connect to API. Retrying...`);
    } else {
      console.error(`[${new Date().toISOString()}] Error polling queue:`, error.message);
    }
  }
}

async function processTask(item) {
  console.log(`[${new Date().toISOString()}] Processing task ${item.taskId} - Action: ${item.action}`);
  
  try {
    // Simulate some processing work
    await simulateWork(item);
    
    // Perform action-specific processing
    switch (item.action) {
      case 'created':
        console.log(`  ✓ Task ${item.taskId} created and logged`);
        await logTaskCreation(item.taskId);
        break;
      case 'updated':
        console.log(`  ✓ Task ${item.taskId} updated and logged`);
        await logTaskUpdate(item.taskId);
        break;
      case 'deleted':
        console.log(`  ✓ Task ${item.taskId} deleted and logged`);
        await logTaskDeletion(item.taskId);
        break;
      default:
        console.log(`  ? Unknown action: ${item.action}`);
    }
  } catch (error) {
    console.error(`  ✗ Error processing task ${item.taskId}:`, error.message);
  }
}

async function simulateWork(item) {
  // Simulate some async work (e.g., sending emails, notifications, etc.)
  return new Promise(resolve => {
    setTimeout(resolve, 1000); // 1 second delay
  });
}

async function logTaskCreation(taskId) {
  try {
    const response = await axios.get(`${API_URL}/api/tasks/${taskId}`);
    const task = response.data;
    console.log(`  📝 New task: "${task.title}" (Priority: ${task.priority})`);
  } catch (error) {
    console.error(`  Error fetching task ${taskId}:`, error.message);
  }
}

async function logTaskUpdate(taskId) {
  try {
    const response = await axios.get(`${API_URL}/api/tasks/${taskId}`);
    const task = response.data;
    console.log(`  📝 Updated task: "${task.title}" (Status: ${task.status})`);
  } catch (error) {
    // Task might have been deleted
    console.log(`  Task ${taskId} no longer exists`);
  }
}

async function logTaskDeletion(taskId) {
  console.log(`  🗑️  Task ${taskId} has been removed`);
}

async function displayStats() {
  try {
    const response = await axios.get(`${API_URL}/api/stats`);
    const stats = response.data;
    console.log('\n' + '='.repeat(50));
    console.log('📊 Task Statistics:');
    console.log(`  Total Tasks: ${stats.total}`);
    console.log(`  Pending: ${stats.pending}`);
    console.log(`  In Progress: ${stats.inProgress}`);
    console.log(`  Completed: ${stats.completed}`);
    console.log(`  Queue Size: ${stats.queueSize}`);
    console.log('='.repeat(50) + '\n');
  } catch (error) {
    // Silently fail if API is not available
  }
}

// Wait for API to be ready
async function waitForAPI() {
  console.log('Waiting for API to be ready...');
  let attempts = 0;
  const maxAttempts = 30;

  while (attempts < maxAttempts) {
    try {
      await axios.get(`${API_URL}/health`);
      console.log('✓ API is ready!');
      return true;
    } catch (error) {
      attempts++;
      console.log(`Attempt ${attempts}/${maxAttempts} - API not ready yet...`);
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
  }

  console.error('Failed to connect to API after maximum attempts');
  return false;
}

// Main worker loop
async function startWorker() {
  const apiReady = await waitForAPI();
  
  if (!apiReady) {
    console.error('Cannot start worker - API is not available');
    process.exit(1);
  }

  console.log('Worker started successfully!');
  console.log(`Polling interval: ${POLL_INTERVAL}ms\n`);

  // Display stats every 30 seconds
  setInterval(displayStats, 30000);

  // Poll the queue
  setInterval(pollQueue, POLL_INTERVAL);
  
  // Initial poll
  pollQueue();
}

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('Worker shutting down...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('Worker shutting down...');
  process.exit(0);
});

// Start the worker
startWorker();

