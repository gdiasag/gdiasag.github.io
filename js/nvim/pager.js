import { bar } from "./bar.js";

export const buffer = document.querySelector("[data-file]");
const lineHeight = (() => {
  const style = getComputedStyle(buffer ?? document.body);
  return parseFloat(style.lineHeight) || parseFloat(style.fontSize) * 1.5;
})();

const visibleHeight = () => innerHeight - bar.offsetHeight;

export const scroll = (lines) => scrollBy(0, lines * lineHeight);
export const page = (pages) => scrollBy(0, pages * visibleHeight());
export const top = () => scrollTo(0, 0);
export const bottom = () => scrollTo(0, document.documentElement.scrollHeight);

export function goToLine(line) {
  const start = buffer ? buffer.getBoundingClientRect().top + scrollY : 0;
  scrollTo(0, start + (line - 1) * lineHeight);
}

// Markdown headings, or the "===" and "---" lines that start a help section.
const headings = "h1, h2, h3, h4, h5, h6, .line:has(> :is(.markup-heading-1-delimiter, .markup-heading-2-delimiter))";

export function heading(step) {
  const lines = [...(buffer ?? document).querySelectorAll(`main :is(${headings})`)].map((h) => {
    return h.getBoundingClientRect().top + parseFloat(getComputedStyle(h).paddingTop);
  });
  const target = step > 0 ? lines.find((top) => top > 1) : lines.findLast((top) => top < -1);
  if (target === undefined) return step > 0 ? bottom() : top();
  scrollBy(0, target);
}

export function position() {
  if (!buffer) return { line: 1, total: 1 };
  const box = buffer.getBoundingClientRect();
  const total = Math.max(1, Math.round(box.height / lineHeight));
  const end = scrollY + innerHeight >= document.documentElement.scrollHeight - 1;
  const line = end ? total : Math.min(Math.max(Math.round(-box.top / lineHeight) + 1, 1), total);
  return { line, total };
}

export function parent() {
  if (buffer?.dataset.parent) return buffer.dataset.parent;
  const path = location.pathname.replace(/\/(index\.html)?$/, "");
  return path ? `${path.slice(0, path.lastIndexOf("/"))}/` : null;
}

export function quit() {
  const destination = parent();
  if (destination) location.href = destination;
}
