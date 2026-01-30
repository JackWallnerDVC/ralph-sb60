---
layout: page
title: The Analyst
permalink: /authors/analyst/
---

<div style="text-align: center; margin-bottom: 2rem;">
  <img src="/assets/images/authors/marcus-chen.jpg" alt="Marcus Chen" class="persona-avatar" style="width: 150px; height: 150px; border-radius: 50%; margin-bottom: 1rem; object-fit: cover;">
  <h1 style="color: var(--navy-primary);">Marcus Chen</h1>
  <p style="color: var(--text-secondary); font-size: 1.125rem; margin-bottom: 0.5rem;">The Analyst</p>
  <p style="color: #718096; font-size: 0.9375rem;">📍 Boston, MA</p>
</div>

## About Marcus

Marcus earned his master's in statistics from MIT and spent three years as a quantitative analyst at a hedge fund before chasing his true passion: sports analytics. His research on fourth-down decision-making has been cited by NFL coaches, and his weekly columns blend rigorous data with accessible storytelling. When the spreadsheets start talking, Marcus listens.

## My Beat

- Betting odds and line movements
- Team statistics and comparisons
- Matchup analysis
- Historical SB trends
- Player prop bets
- Weather impact analysis
- Coaching strategy breakdown

## Writing Style

> Data-forward, bullet points, clear conclusions. Stats-heavy but readable.

## Latest from Marcus

{% assign analyst_posts = site.posts | where: "author", "analyst" %}
{% for post in analyst_posts limit:5 %}
- [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

[View all posts by Marcus &rarr;](/)
