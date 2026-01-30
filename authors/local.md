---
layout: page
title: The Local
permalink: /authors/local/
---

<div style="text-align: center; margin-bottom: 2rem;">
  <img src="/assets/images/authors/tony-moretti.jpg" alt="Tony Moretti" class="persona-avatar" style="width: 150px; height: 150px; border-radius: 50%; margin-bottom: 1rem; object-fit: cover;">
  <h1 style="color: var(--navy-primary);">Tony Moretti</h1>
  <p style="color: var(--text-secondary); font-size: 1.125rem; margin-bottom: 0.5rem;">The Local</p>
  <p style="color: #718096; font-size: 0.9375rem;">📍 San Francisco, CA</p>
</div>

## About Tony

Tony grew up in the Mission District watching 49ers games at his uncle's sports bar and has spent the last 15 years working in San Francisco's hospitality scene. He's the guy you call when you need to know where to watch the game, where to park, or which bartender pours the strongest Irish coffee. For Super Bowl 60, he's your guide to experiencing it like a true local.

## My Beat

- Santa Clara and Bay Area restaurants
- Fan events and watch parties
- Transportation and logistics
- Hotel recommendations
- Local attractions near Levi's Stadium
- Weather and what to wear
- Tailgating culture

## Writing Style

> First-person friendly, "you gotta check out...", conversational and welcoming.

## Latest from Tony

{% assign local_posts = site.posts | where: "author", "local" %}
{% for post in local_posts limit:5 %}
- [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

[View all posts by Tony &rarr;](/)
