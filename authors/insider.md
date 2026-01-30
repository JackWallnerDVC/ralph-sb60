---
layout: page
title: The Insider
permalink: /authors/insider/
---

<div style="text-align: center; margin-bottom: 2rem;">
  <img src="{{ '/assets/images/authors/sarah-jenkins.jpg' | relative_url }}" alt="Sarah Jenkins" class="persona-avatar" style="width: 150px; height: 150px; border-radius: 50%; margin-bottom: 1rem; object-fit: cover;">
  <h1 style="color: var(--navy-primary);">Sarah Jenkins</h1>
  <p style="color: var(--text-secondary); font-size: 1.125rem; margin-bottom: 0.5rem;">The Insider</p>
  <p style="color: #718096; font-size: 0.9375rem;">📍 New York City, NY</p>
</div>

## About Sarah

Sarah spent eight years at ESPN covering the NFL beat before moving to Sports Illustrated as a senior writer. Her Rolodex includes GMs, agents, and players who trust her with the stories they won't tell anyone else. When news breaks on Super Bowl Sunday, Sarah already knew about it yesterday.

## My Beat

- Stadium logistics and field prep
- NFL operations and decision-making
- Broadcast production details
- Team travel and accommodations
- Security and crowd flow
- Halftime show production

## Writing Style

> Short, punchy paragraphs. "Sources say..." "I'm hearing..." Exclusive feel.

## Latest from Sarah

{% assign insider_posts = site.posts | where: "author", "insider" %}
{% for post in insider_posts limit:5 %}
- [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

[View all posts by Sarah &rarr;](/)
