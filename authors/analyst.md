---
layout: page
title: The Analyst
permalink: /authors/analyst/
---

<div style="text-align: center; margin-bottom: 2rem;">
  <img src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&crop=face" alt="The Analyst" class="persona-avatar" style="width: 120px; height: 120px; margin-bottom: 1rem;">
  <h1 style="color: var(--navy-primary);">The Analyst</h1>
  <p style="color: var(--text-secondary); max-width: 500px; margin: 0 auto;">Numbers don't lie. Breaking down matchups, odds, and what the data says about SB60.</p>
</div>

## My Beat

- Betting odds and line movements
- Team statistics and comparisons
- Matchup analysis
- Historical SB trends
- Player prop bets
- Weather impact analysis
- Coaching strategy breakdown

## Latest from The Analyst

{% assign analyst_posts = site.posts | where: "author", "analyst" %}
{% for post in analyst_posts limit:5 %}
- [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

[View all posts by The Analyst &rarr;](/)
