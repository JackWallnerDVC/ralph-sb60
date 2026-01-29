---
layout: page
title: The Insider
permalink: /authors/insider/
---

<div style="text-align: center; margin-bottom: 2rem;">
  <img src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face" alt="The Insider" class="persona-avatar" style="width: 120px; height: 120px; margin-bottom: 1rem;">
  <h1 style="color: var(--navy-primary);">The Insider</h1>
  <p style="color: var(--text-secondary); max-width: 500px; margin: 0 auto;">Behind-the-scenes access to the NFL machine. Stadium logistics, broadcast details, locker room whispers.</p>
</div>

## My Beat

- Stadium logistics and field prep
- NFL operations and decision-making
- Broadcast production details
- Team travel and accommodations
- Security and crowd flow
- Halftime show production

## Latest from The Insider

{% assign insider_posts = site.posts | where: "author", "insider" %}
{% for post in insider_posts limit:5 %}
- [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

[View all posts by The Insider &rarr;](/)
