---
layout: page
title: The Local
permalink: /authors/local/
---

<img src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop&crop=face" alt="The Local" class="author-page-avatar">

# The Local

Born and raised in the Bay. I know the spots, the shortcuts, and the secrets.

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
