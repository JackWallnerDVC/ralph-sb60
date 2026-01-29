---
layout: page
title: The Insider
permalink: /authors/insider/
---

<img src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face" alt="The Insider" class="author-page-avatar">

# The Insider

I get the access. The behind-the-scenes, the locker room, the control room.

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
