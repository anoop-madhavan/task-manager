import React from 'react';
import './Stats.css';

function Stats({ stats }) {
  return (
    <div className="stats-container">
      <div className="stat-card">
        <div className="stat-icon">📊</div>
        <div className="stat-content">
          <div className="stat-value">{stats.total}</div>
          <div className="stat-label">Total Tasks</div>
        </div>
      </div>

      <div className="stat-card pending">
        <div className="stat-icon">⏸️</div>
        <div className="stat-content">
          <div className="stat-value">{stats.pending}</div>
          <div className="stat-label">Pending</div>
        </div>
      </div>

      <div className="stat-card in-progress">
        <div className="stat-icon">⚡</div>
        <div className="stat-content">
          <div className="stat-value">{stats.inProgress}</div>
          <div className="stat-label">In Progress</div>
        </div>
      </div>

      <div className="stat-card completed">
        <div className="stat-icon">✅</div>
        <div className="stat-content">
          <div className="stat-value">{stats.completed}</div>
          <div className="stat-label">Completed</div>
        </div>
      </div>

      <div className="stat-card queue">
        <div className="stat-icon">🔄</div>
        <div className="stat-content">
          <div className="stat-value">{stats.queueSize}</div>
          <div className="stat-label">Queue Size</div>
        </div>
      </div>
    </div>
  );
}

export default Stats;

