---
layout: page
title: The Analyst
permalink: /authors/analyst/
---

<img src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&crop=face" alt="The Analyst" class="author-page-avatar">

# The Analyst

Numbers don't lie. I dig into the data so you don't have to.

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
