---
layout: dir
title: "gustavos.terminal/themes"
cmd: "eza -laa"
pwd: "themes"
---

<div class="term">
  total {{ site.themes.size | plus: 2 }}
</div>
<table class="term">
  {% assign dates = site.themes | map: "date" %}
  {% include term-dots.html dates=dates %}
  {% for theme in site.themes %}
    {% capture href %}#theme-{{ theme.name }}{% endcapture %}
    {% include ls-row.html mode="lrwxrwxrwx" bytes=32 owner=theme.author date=theme.date href=href name=theme.name target=theme.href %}
  {% endfor %}
</table>
