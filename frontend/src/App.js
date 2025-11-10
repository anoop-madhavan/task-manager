import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';
import TaskForm from './components/TaskForm';
import TaskList from './components/TaskList';
import Stats from './components/Stats';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';
const INSTANCE_NAME = process.env.REACT_APP_INSTANCE_NAME || 'Local';
const IMAGE_VERSION = process.env.REACT_APP_IMAGE_VERSION || 'dev';

function App() {
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    inProgress: 0,
    completed: 0,
    queueSize: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [backendVersion, setBackendVersion] = useState(null);

  // Fetch tasks
  const fetchTasks = async () => {
    try {
      const response = await axios.get(`${API_URL}/api/tasks`);
      setTasks(response.data);
      setError(null);
    } catch (err) {
      setError('Failed to fetch tasks. Is the backend running?');
      console.error('Error fetching tasks:', err);
    } finally {
      setLoading(false);
    }
  };

  // Fetch stats
  const fetchStats = async () => {
    try {
      const response = await axios.get(`${API_URL}/api/stats`);
      setStats(response.data);
    } catch (err) {
      console.error('Error fetching stats:', err);
    }
  };

  // Create task
  const createTask = async (taskData) => {
    try {
      const response = await axios.post(`${API_URL}/api/tasks`, taskData);
      setTasks([...tasks, response.data]);
      fetchStats();
      return response.data;
    } catch (err) {
      setError('Failed to create task');
      console.error('Error creating task:', err);
      throw err;
    }
  };

  // Update task
  const updateTask = async (id, updates) => {
    try {
      const response = await axios.put(`${API_URL}/api/tasks/${id}`, updates);
      setTasks(tasks.map(task => task.id === id ? response.data : task));
      fetchStats();
      return response.data;
    } catch (err) {
      setError('Failed to update task');
      console.error('Error updating task:', err);
      throw err;
    }
  };

  // Delete task
  const deleteTask = async (id) => {
    try {
      await axios.delete(`${API_URL}/api/tasks/${id}`);
      setTasks(tasks.filter(task => task.id !== id));
      fetchStats();
    } catch (err) {
      setError('Failed to delete task');
      console.error('Error deleting task:', err);
      throw err;
    }
  };

  // Fetch backend version
  const fetchBackendVersion = async () => {
    try {
      const response = await axios.get(`${API_URL}/api/version`);
      setBackendVersion(response.data);
    } catch (err) {
      console.error('Error fetching backend version:', err);
    }
  };

  // Initial fetch
  useEffect(() => {
    fetchTasks();
    fetchStats();
    fetchBackendVersion();
  }, []);

  // Auto-refresh every 5 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      fetchTasks();
      fetchStats();
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="App">
        <div className="loading">Loading...</div>
      </div>
    );
  }

  return (
    <div className="App">
      <header className="App-header">
        <h1>📋 Task Manager</h1>
        <p className="subtitle">Simple task management for learning</p>
        {INSTANCE_NAME && INSTANCE_NAME !== 'Local' && (
          <div className="instance-badge">{INSTANCE_NAME}</div>
        )}
        <div className="version-info">
          <div className="version-item">
            <span className="version-label">Frontend:</span>
            <span className="version-value">{IMAGE_VERSION}</span>
          </div>
          {backendVersion && (
            <div className="version-item">
              <span className="version-label">Backend:</span>
              <span className="version-value">{backendVersion.version}</span>
            </div>
          )}
        </div>
      </header>

      {error && (
        <div className="error-banner">
          {error}
        </div>
      )}

      <div className="container">
        <Stats stats={stats} />
        <TaskForm onSubmit={createTask} />
        <TaskList 
          tasks={tasks} 
          onUpdate={updateTask}
          onDelete={deleteTask}
        />
      </div>
    </div>
  );
}

export default App;

