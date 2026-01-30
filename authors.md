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
  grid-template-columns: 140px 1fr;
  gap: 2rem;
  background: white;
  border-radius: 20px;
  padding: 2.5rem;
  box-shadow: 0 4px 20px rgba(0,0,0,0.08);
  transition: transform 0.3s ease;
  align-items: start;
}

.author-card:hover {
  transform: translateY(-4px);
}

.author-avatar {
  width: 120px;
  height: 120px;
  border-radius: 24px;
  overflow: hidden;
  background: linear-gradient(135deg, #f0f4f8 0%, #e2e8f0 100%);
  flex-shrink: 0;
}

.author-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.author-info h2 {
  color: #1a365d;
  margin-bottom: 0.5rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.75rem;
}

.author-badge {
  font-size: 0.6875rem;
  padding: 0.25rem 0.75rem;
  background: #2d7d32;
  color: white;
  border-radius: 100px;
  font-weight: 700;
  letter-spacing: 0.05em;
}

.author-location {
  font-size: 0.875rem;
  color: #718096;
  margin-bottom: 0.75rem;
}

.author-bio {
  color: #4a5568;
  line-height: 1.7;
  margin-bottom: 1rem;
  font-size: 1.0625rem;
}

.author-full-bio {
  color: #4a5568;
  line-height: 1.7;
  margin-bottom: 1.25rem;
  font-size: 0.9375rem;
  padding: 1rem 1.25rem;
  background: #f7fafc;
  border-radius: 12px;
  border-left: 3px solid #2d7d32;
}

.author-style {
  font-size: 0.9375rem;
  color: #718096;
  font-style: italic;
  margin-bottom: 1.25rem;
}

.author-topics {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.topic-pill {
  font-size: 0.8125rem;
  padding: 0.5rem 1rem;
  background: rgba(45, 125, 50, 0.1);
  color: #2d7d32;
  border-radius: 100px;
  font-weight: 600;
}

@media (max-width: 768px) {
  .author-card {
    grid-template-columns: 1fr;
    text-align: center;
  }
  .author-avatar {
    margin: 0 auto;
    width: 100px;
    height: 100px;
  }
  .author-info h2 {
    justify-content: center;
    flex-wrap: wrap;
  }
  .author-topics {
    justify-content: center;
  }
  .author-hero h1 {
    font-size: 2rem;
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
      <div class="author-avatar">
        <img src="{{ persona[1].avatar }}" alt="{{ persona[1].name }}">
      </div>
      <div class="author-info">
        <h2>
          {{ persona[1].name }}
          <span class="author-badge">{{ persona[0] | upcase }}</span>
        </h2>
        <p class="author-location">📍 {{ persona[1].location }}</p>
        <p class="author-bio">{{ persona[1].bio }}</p>
        <p class="author-full-bio">{{ persona[1].full_bio }}</p>
        <p class="author-style">Voice: "{{ persona[1].style }}"</p>
        <div class="author-topics">
          {% for topic in persona[1].topics %}
          <span class="topic-pill">{{ topic }}</span>
          {% endfor %}
        </div>
      </div>
    </div>
    {% endfor %}
  </div>
</div>
