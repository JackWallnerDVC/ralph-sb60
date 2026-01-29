---
layout: page
title: The Local
permalink: /authors/local/
---

<div style="text-align: center; margin-bottom: 2rem;">
  <img src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop&crop=face" alt="The Local" class="persona-avatar" style="width: 120px; height: 120px; margin-bottom: 1rem;">
  <h1 style="color: var(--navy-primary);">The Local</h1>
  <p style="color: var(--text-secondary); max-width: 500px; margin: 0 auto;">Born and raised in the Bay. Your guide to SF, Santa Clara, and the ultimate fan experience.</p>
</div>

## My Beat

- Santa Clara and Bay Area restaurants
- Fan events and watch parties
- Transportation and logistics
- Hotel recommendations
- Local attractions near Levi's Stadium
- Weather and what to wear
- Tailgating culture

## Latest from The Local

{% assign local_posts = site.posts | where: "author", "local" %}
{% for post in local_posts limit:5 %}
- [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

[View all posts by The Local &rarr;](/)
