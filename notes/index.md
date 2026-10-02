---
layout: dir
title: gustavos.terminal/notes
cmd: "eza -laa"
pwd: notes
---

<div class="term">
  total {{ site.posts.size | plus: site.external-posts.size | plus: 2 }}
</div>
<table class="term">
  {% assign external = site.external-posts | map: "date" %}
  {% assign dates = site.posts | map: "date" | concat: external %}
  {% include term-dots.html dates=dates %}
  {% for item in site.posts %}
    {% assign size = item.content | size %}
    {% assign owner = item.author.name | default: item.author | split: " " | first | downcase %}
    {% include ls-row.html mode=".rw-r--r--" bytes=size owner=owner date=item.date href=item.url name=item.title %}
  {% endfor %}
  {% for post in site.external-posts %}
    {% include ls-row.html mode="lrwxrwxrwx" bytes=32 date=post.date href=post.href name=post.title %}
  {% endfor %}
</table>
