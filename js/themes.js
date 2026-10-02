---
layout: null
---
{%- assign light = site.themes | where: "default_light", true | first -%}

window.colorscheme = (function () {
  var KEY = "site-theme";
  var names = {{ site.themes | map: "name" | jsonify }};
  var light = {{ light.name | jsonify }};
  var root = document.documentElement;
  var dark = root.dataset.theme;
  var system = matchMedia("(prefers-color-scheme: light)");
  var picked = null;

  try {
    var saved = localStorage.getItem(KEY);
    if (names.indexOf(saved) >= 0) picked = saved;
  } catch (_) {}

  function chosen() {
    return picked || (light && system.matches ? light : dark);
  }

  function show(name) {
    root.dataset.theme = name;
    paint();
  }

  var favicon = null;
  function paint() {
    var style = getComputedStyle(root);
    var bg = style.getPropertyValue("--Normal-bg").trim();
    var fg = style.getPropertyValue("--Normal-fg").trim();
    var link = document.querySelector('link[rel="icon"]');
    if (!bg || !fg || !link) return;
    favicon = favicon || fetch("/favicon.svg").then(function (response) { return response.text(); });
    favicon.then(function (svg) {
      var icon = new DOMParser().parseFromString(svg, "image/svg+xml");
      icon.querySelector(".bg").setAttribute("fill", bg);
      icon.querySelector(".fg").setAttribute("fill", fg);
      link.href = "data:image/svg+xml," + encodeURIComponent(new XMLSerializer().serializeToString(icon));
    }).catch(function () {});
  }
  addEventListener("load", paint);

  function apply(name) {
    picked = name;
    show(name);
    try { localStorage.setItem(KEY, name); } catch (_) {}
  }

  show(chosen());
  system.addEventListener("change", function () {
    show(chosen());
  });

  function link(e) {
    return e.target.closest && e.target.closest('a[href^="#theme-"]');
  }

  function named(a) {
    return a.getAttribute("href").slice("#theme-".length);
  }

  document.addEventListener("click", function (e) {
    var a = link(e);
    if (!a) return;
    e.preventDefault();
    apply(named(a));
  });

  return {
    names: names,
    show: show,
    apply: apply,
    chosen: chosen,
    current: function () { return root.dataset.theme; },
  };
})();
