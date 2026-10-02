---
layout: dir
title: gustavos.terminal/books
cmd: "eza -laa"
pwd: books
---

<div class="term">
  total {{ site.books.size | plus: 2 }}
</div>
<table class="term">
  {% assign dates = site.books | map: "date" %}
  {% include term-dots.html dates=dates %}
  {% assign books = site.books | sort: "title" %}
  {% for item in books %}
    {% if item.symlink %}
      {% include ls-row.html mode="lrwxrwxrwx" bytes=32 date=item.date href=item.symlink name=item.title %}
    {% endif %}
    {% if item.pdf %}
      {% capture name %}{{ item.title }}.pdf{% endcapture %}
      {% include ls-row.html mode=".rw-r--r--" bytes=item.size date=item.date href=item.pdf name=name blank=item.symlink %}
    {% endif %}
  {% endfor %}
</table>
