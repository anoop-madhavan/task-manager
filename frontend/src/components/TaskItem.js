import React, { useState } from 'react';
import './TaskItem.css';

function TaskItem({ task, onUpdate, onDelete }) {
  const [isDeleting, setIsDeleting] = useState(false);

  const handleStatusChange = async (newStatus) => {
    try {
      await onUpdate(task.id, { status: newStatus });
    } catch (err) {
      console.error('Error updating status:', err);
    }
  };

  const handleDelete = async () => {
    if (window.confirm('Are you sure you want to delete this task?')) {
      setIsDeleting(true);
      try {
        await onDelete(task.id);
      } catch (err) {
        console.error('Error deleting task:', err);
        setIsDeleting(false);
      }
    }
  };

  const getPriorityClass = (priority) => {
    switch (priority) {
      case 'high':
        return 'priority-high';
      case 'medium':
        return 'priority-medium';
      case 'low':
        return 'priority-low';
      default:
        return '';
    }
  };

  const getStatusClass = (status) => {
    switch (status) {
      case 'completed':
        return 'status-completed';
      case 'in-progress':
        return 'status-in-progress';
      case 'pending':
        return 'status-pending';
      default:
        return '';
    }
  };

  return (
    <div className={`task-item ${getStatusClass(task.status)} ${isDeleting ? 'deleting' : ''}`}>
      <div className="task-header">
        <div className="task-title-section">
          <h3 className="task-title">{task.title}</h3>
          <span className={`priority-badge ${getPriorityClass(task.priority)}`}>
            {task.priority}
          </span>
        </div>
        <button 
          className="delete-btn" 
          onClick={handleDelete}
          disabled={isDeleting}
          title="Delete task"
        >
          🗑️
        </button>
      </div>

      {task.description && (
        <p className="task-description">{task.description}</p>
      )}

      <div className="task-footer">
        <div className="status-buttons">
          <button
            className={`status-btn ${task.status === 'pending' ? 'active' : ''}`}
            onClick={() => handleStatusChange('pending')}
            disabled={task.status === 'pending'}
          >
            ⏸️ Pending
          </button>
          <button
            className={`status-btn ${task.status === 'in-progress' ? 'active' : ''}`}
            onClick={() => handleStatusChange('in-progress')}
            disabled={task.status === 'in-progress'}
          >
            ⚡ In Progress
          </button>
          <button
            className={`status-btn ${task.status === 'completed' ? 'active' : ''}`}
            onClick={() => handleStatusChange('completed')}
            disabled={task.status === 'completed'}
          >
            ✅ Completed
          </button>
        </div>
        <div className="task-meta">
          <span className="task-date">
            Created: {new Date(task.createdAt).toLocaleDateString()}
          </span>
        </div>
      </div>
    </div>
  );
}

export default TaskItem;

