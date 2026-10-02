import { message } from "./bar.js";
import { buffer } from "./pager.js";

const scope = buffer ?? document.querySelector("main") ?? document.body;
let pattern = "";
let backward = false;
let origin = 0;
let matches = [];
let current = -1;

export function start(reverse) {
  backward = reverse;
  origin = scrollY;
}

export function preview(text) {
  clear();
  scrollTo(0, origin);
  if (!text) return;
  matches = mark(compile(text));
  if (matches.length > 0) show(...nearest());
}

export function search(text) {
  if (text === null) {
    clear();
    scrollTo(0, origin);
    return;
  }
  pattern = text || pattern;
  if (!pattern) return message("E35: No previous regular expression", "error");
  if (text === "") matches = mark(compile(pattern));
  if (matches.length === 0) return message(`E486: Pattern not found: ${pattern}`, "error");
  scrollTo(0, origin);
  report(...nearest(), !backward);
}

export function next(reverse = false) {
  if (!pattern) return message("E35: No previous regular expression", "error");
  if (matches.length === 0) matches = mark(compile(pattern));
  if (matches.length === 0) return message(`E486: Pattern not found: ${pattern}`, "error");
  const forward = backward === reverse;
  const index = current + (forward ? 1 : -1);
  report((index + matches.length) % matches.length, index < 0 || index >= matches.length, forward);
}

export function clear() {
  for (const m of matches) m.replaceWith(m.textContent);
  scope.normalize();
  matches = [];
  current = -1;
}

function nearest() {
  if (backward) {
    const index = matches.findLastIndex((m) => m.getBoundingClientRect().top < 0);
    return index === -1 ? [matches.length - 1, true] : [index, false];
  }
  const index = matches.findIndex((m) => m.getBoundingClientRect().top >= 0);
  return index === -1 ? [0, true] : [index, false];
}

function show(index) {
  matches[current]?.classList.remove("current");
  current = index;
  matches[current].classList.add("current");
  matches[current].scrollIntoView({ block: "center" });
}

function report(index, wrapped, forward) {
  show(index);
  if (wrapped) {
    const [hit, continuing] = forward ? ["BOTTOM", "TOP"] : ["TOP", "BOTTOM"];
    message(`search hit ${hit}, continuing at ${continuing}`, "warning");
  } else {
    message(`${backward ? "?" : "/"}${pattern}  [${current + 1}/${matches.length}]`);
  }
}

function compile(text) {
  const flags = /[A-Z]/.test(text) ? "g" : "gi";
  try {
    return new RegExp(text, flags);
  } catch {
    return new RegExp(text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), flags);
  }
}

function mark(regex) {
  const walker = document.createTreeWalker(scope, NodeFilter.SHOW_TEXT, {
    acceptNode: (node) =>
      node.parentElement.closest("script, style, .vim-bar, .visually-hidden")
        ? NodeFilter.FILTER_REJECT
        : NodeFilter.FILTER_ACCEPT,
  });
  const nodes = [];
  while (walker.nextNode()) nodes.push(walker.currentNode);

  return nodes.flatMap((node) => {
    const ranges = [...node.data.matchAll(regex)]
      .filter((m) => m[0].length > 0)
      .map((m) => [m.index, m.index + m[0].length]);

    return ranges.reverse().map(([start, end]) => {
      const text = node.splitText(start);
      text.splitText(end - start);
      const mark = document.createElement("mark");
      mark.className = "search";
      text.replaceWith(mark);
      mark.append(text);
      return mark;
    }).reverse();
  });
}
