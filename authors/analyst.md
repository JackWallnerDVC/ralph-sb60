---
layout: page
title: The Analyst
permalink: /authors/analyst/
---

# The Analyst

<img src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&crop=face" alt="The Analyst" style="width: 120px; height: 120px; border-radius: 16px; margin: 1rem 0;">

Numbers don't lie. The odds, the trends, the matchups—I break it all down.

## My Beat

- Betting odds and line movements
- Team statistics and comparisons
- Matchup analysis
- Historical Super Bowl trends
- Player prop analysis
- Weather impact on performance

## Latest from The Analyst

{% assign analyst_posts = site.posts | where: "author", "analyst" %}
{% for post in analyst_posts limit:5 %}
- [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

[View all posts by The Analyst &rarr;](/)
