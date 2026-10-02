import { bar, clearMessage, prompt } from "./bar.js";
import { cancel, complete, preview, prefetch, run } from "./commands.js";
import * as float from "./hover.js";
import { setMode } from "./lualine.js";
import * as pager from "./pager.js";
import * as search from "./search.js";

const keys = {
  j: () => pager.scroll(1),
  k: () => pager.scroll(-1),
  d: () => pager.page(0.5),
  u: () => pager.page(-0.5),
  f: () => pager.page(1),
  b: () => pager.page(-1),
  g: pager.top,
  "<": pager.top,
  G: pager.bottom,
  ">": pager.bottom,
  q: pager.quit,
  n: () => search.next(),
  N: () => search.next(true),
  "]]": () => pager.heading(1),
  "[[": () => pager.heading(-1),
  K: float.hover,
  ":": commandLine,
  "/": () => find(false),
  "?": () => find(true),
  Escape: clearMessage,
};

async function commandLine() {
  prefetch();
  const line = await command(":", { complete, live: preview });
  if (line === null) cancel();
  run(line);
}

async function find(backward) {
  search.start(backward);
  search.search(await command(backward ? "?" : "/", { live: search.preview }));
}

async function command(char, options) {
  setMode("command");
  const text = await prompt(char, options);
  setMode("normal");
  return text;
}

document.addEventListener("selectionchange", () => {
  if (document.activeElement?.closest(".vim-prompt")) return;
  setMode(getSelection().isCollapsed ? "normal" : "visual");
});

let pending = "";
let timeout;

document.addEventListener("keydown", (e) => {
  if (e.ctrlKey || e.metaKey || e.altKey || e.target.closest("input, textarea, select, [contenteditable]")) return;
  const typed = pending + e.key;
  const waits = Object.keys(keys).some((key) => key.length > typed.length && key.startsWith(typed));
  const action = keys[typed];
  pending = "";
  clearTimeout(timeout);
  float.close();
  if (!action && !waits) return;
  e.preventDefault();
  clearMessage();
  if (waits) {
    pending = typed;
    timeout = setTimeout(() => (pending = ""), 1000);
    return;
  }
  action();
});

addEventListener("wheel", clearMessage, { passive: true });
addEventListener("touchmove", clearMessage, { passive: true });

bar.addEventListener("click", (e) => {
  if (!e.target.closest(".vim-prompt")) commandLine();
});
