---
layout: page
title: The Local
permalink: /authors/local/
---

# The Local

<img src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop&crop=face" alt="The Local" style="width: 120px; height: 120px; border-radius: 16px; margin: 1rem 0;">

Born and raised in the Bay. I know the spots, the shortcuts, the vibes.

## My Beat

- Santa Clara and SF restaurants
- Fan events and watch parties
- Transportation and parking
- Hotel recommendations
- Local attractions
- Weather and what to wear
- Tailgating spots

## Latest from The Local

{% assign local_posts = site.posts | where: "author", "local" %}
{% for post in local_posts limit:5 %}
- [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

[View all posts by The Local &rarr;](/)
