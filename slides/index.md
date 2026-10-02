---
layout: dir
title: gustavos.terminal/slides
cmd: "eza -laa"
pwd: slides
---

<div class="term">
  total {{ site.slides.size | plus: 2 }}
</div>
<table class="term">
  {% assign dates = site.slides | map: "date" %}
  {% include term-dots.html dates=dates %}
  {% for item in site.slides %}
    {% if item.symlink %}
      {% capture name %}{{ item.title }}.{{ item.extension | default: "mp4" }}{% endcapture %}
      {% include ls-row.html mode="lrwxrwxrwx" bytes=32 date=item.date href=item.symlink name=name %}
    {% endif %}
    {% if item.pdf %}
      {% capture name %}{{ item.title }}.pdf{% endcapture %}
      {% include ls-row.html mode=".rw-r--r--" bytes=item.size date=item.date href=item.pdf name=name blank=item.symlink %}
    {% endif %}
  {% endfor %}
</table>
