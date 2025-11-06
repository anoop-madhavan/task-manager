import React from 'react';
import TaskItem from './TaskItem';
import './TaskList.css';

function TaskList({ tasks, onUpdate, onDelete }) {
  if (tasks.length === 0) {
    return (
      <div className="task-list-container">
        <h2>📝 Tasks</h2>
        <div className="empty-state">
          <p>No tasks yet. Create your first task above!</p>
        </div>
      </div>
    );
  }

  // Sort tasks: pending first, then in-progress, then completed
  const sortedTasks = [...tasks].sort((a, b) => {
    const statusOrder = { 'pending': 0, 'in-progress': 1, 'completed': 2 };
    return statusOrder[a.status] - statusOrder[b.status];
  });

  return (
    <div className="task-list-container">
      <h2>📝 Tasks ({tasks.length})</h2>
      <div className="task-list">
        {sortedTasks.map(task => (
          <TaskItem
            key={task.id}
            task={task}
            onUpdate={onUpdate}
            onDelete={onDelete}
          />
        ))}
      </div>
    </div>
  );
}

export default TaskList;

