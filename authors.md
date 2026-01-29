---
layout: page
title: Authors
permalink: /authors/
---

# Meet the Team

Our coverage comes from three distinct voices, each bringing their own expertise to Super Bowl 60.

{% for persona in site.data.personas %}
## {{ persona[1].avatar }} {{ persona[1].name }}

{{ persona[1].bio }}

**Coverage areas:**
{% for topic in persona[1].topics %}
- {{ topic }}
{% endfor %}

**Writing style:** {{ persona[1].style }}

---
{% endfor %}

## Publishing Schedule

| Time (UTC) | Author | Type |
|------------|--------|------|
| 00:00 | The Insider | Overnight intelligence |
| 06:00 | The Analyst | Morning numbers |
| 12:00 | The Local | Midday guide |
| 18:00 | Rotating | Evening bonus |

*All times UTC. Convert to your timezone [here](https://www.worldtimebuddy.com/).*
