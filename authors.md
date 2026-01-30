---
layout: page
title: Meet the Team
permalink: /authors/
---

<style>
.authors-container {
  max-width: 1000px;
  margin: 0 auto;
}

.author-hero {
  text-align: center;
  padding: 3rem 2rem;
  background: linear-gradient(135deg, #1a365d 0%, #2d7d32 100%);
  border-radius: 20px;
  color: white;
  margin-bottom: 3rem;
}

.author-hero h1 {
  font-size: 2.5rem;
  margin-bottom: 1rem;
}

.author-hero p {
  font-size: 1.125rem;
  opacity: 0.9;
  max-width: 600px;
  margin: 0 auto;
}

.authors-grid {
  display: grid;
  gap: 2rem;
  margin-bottom: 3rem;
}

.author-card {
  display: grid;
  grid-template-columns: 120px 1fr;
  gap: 2rem;
  background: white;
  border-radius: 16px;
  padding: 2rem;
  box-shadow: 0 4px 20px rgba(0,0,0,0.08);
  transition: transform 0.3s ease;
}

.author-card:hover {
  transform: translateY(-4px);
}

.author-avatar {
  width: 120px;
  height: 120px;
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 4rem;
  background: linear-gradient(135deg, #f0f4f8 0%, #e2e8f0 100%);
}

.author-info h2 {
  color: #1a365d;
  margin-bottom: 0.5rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.author-badge {
  font-size: 0.75rem;
  padding: 0.25rem 0.75rem;
  background: #2d7d32;
  color: white;
  border-radius: 100px;
  font-weight: 600;
}

.author-bio {
  color: #4a5568;
  line-height: 1.7;
  margin-bottom: 1rem;
}

.author-style {
  font-size: 0.9375rem;
  color: #718096;
  font-style: italic;
  padding: 1rem;
  background: #f7fafc;
  border-radius: 8px;
  margin-bottom: 1rem;
}

.author-topics {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.topic-pill {
  font-size: 0.8125rem;
  padding: 0.375rem 1rem;
  background: rgba(45, 125, 50, 0.1);
  color: #2d7d32;
  border-radius: 100px;
  font-weight: 500;
}

.schedule-section {
  background: #f7fafc;
  border-radius: 16px;
  padding: 2rem;
}

.schedule-section h2 {
  color: #1a365d;
  margin-bottom: 1.5rem;
  text-align: center;
}

.schedule-table {
  width: 100%;
  border-collapse: collapse;
}

.schedule-table th,
.schedule-table td {
  padding: 1rem;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.schedule-table th {
  color: #718096;
  font-weight: 600;
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.schedule-table tr:hover {
  background: white;
}

.time-cell {
  font-weight: 700;
  color: #1a365d;
  font-family: monospace;
  font-size: 1.1rem;
}

.author-cell {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
}

@media (max-width: 768px) {
  .author-card {
    grid-template-columns: 1fr;
    text-align: center;
  }
  .author-avatar {
    margin: 0 auto;
  }
  .author-topics {
    justify-content: center;
  }
}
</style>

<div class="authors-container">
  <div class="author-hero">
    <h1>🎯 Meet the SB60 Intel Team</h1>
    <p>Three distinct voices. One mission: Delivering the most comprehensive Super Bowl 60 coverage from every angle.</p>
  </div>

  <div class="authors-grid">
    {% for persona in site.data.personas %}
    <div class="author-card">
      <div class="author-avatar">{{ persona[1].avatar }}</div>
      <div class="author-info">
        <h2>
          {{ persona[1].name }}
          <span class="author-badge">{{ persona[0] | upcase }}</span>
        </h2>
        <p class="author-bio">{{ persona[1].bio }}</p>
        <p class="author-style">"{{ persona[1].style }}"</p>
        <div class="author-topics">
          {% for topic in persona[1].topics %}
          <span class="topic-pill">{{ topic }}</span>
          {% endfor %}
        </div>
      </div>
    </div>
    {% endfor %}
  </div>

  <div class="schedule-section">
    <h2>📅 Publishing Schedule</h2>
    <table class="schedule-table">
      <thead>
        <tr>
          <th>Time (UTC)</th>
          <th>Author</th>
          <th>What to Expect</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td class="time-cell">00:00</td>
          <td class="author-cell"><span style="font-size: 1.2rem;">🎭</span> Sarah Jenkins</td>
          <td>Overnight intelligence drops. Sources say...</td>
        </tr>
        <tr>
          <td class="time-cell">06:00</td>
          <td class="author-cell"><span style="font-size: 1.2rem;">📊</span> Marcus Chen</td>
          <td>Morning numbers. Stats, odds, and analysis.</td>
        </tr>
        <tr>
          <td class="time-cell">12:00</td>
          <td class="author-cell"><span style="font-size: 1.2rem;">🌉</span> Tony Moretti</td>
          <td>Midday Bay Area guide. Food, transit, events.</td>
        </tr>
        <tr>
          <td class="time-cell">18:00</td>
          <td class="author-cell"><span style="font-size: 1.2rem;">🎲</span> Rotating</td>
          <td>Evening bonus. Best story of the day wins.</td>
        </tr>
      </tbody>
    </table>
    <p style="text-align: center; margin-top: 1.5rem; color: #718096; font-size: 0.9375rem;">
      All times UTC. <a href="https://www.worldtimebuddy.com/" target="_blank">Convert to your timezone →</a>
    </p>
  </div>
</div>
