import { bar, message } from "./bar.js";

const float = document.createElement("div");
float.className = "vim-float md";
float.hidden = true;
float.setAttribute("role", "note");
document.body.append(float);

let openedAt = 0;

export const close = () => (float.hidden = true);

export function hover() {
  const reference = [...document.querySelectorAll("a.footnote")].find((a) => a.matches(":hover"));
  const note = reference && document.getElementById(decodeURIComponent(reference.hash.slice(1)));
  if (!note) return message("E349: No identifier under cursor", "error");

  float.innerHTML = note.innerHTML;
  float.querySelectorAll(".reversefootnote").forEach((a) => a.remove());
  float.hidden = false;
  openedAt = scrollY;

  const anchor = reference.getBoundingClientRect();
  const block = reference.closest("p, li") ?? reference.parentElement;
  const lineHeight = parseFloat(getComputedStyle(block).lineHeight);
  const blockTop = block.getBoundingClientRect().top;
  const lineTop = blockTop + Math.floor((anchor.bottom - blockTop) / lineHeight) * lineHeight;
  const box = float.getBoundingClientRect();
  const floor = innerHeight - bar.offsetHeight;
  const room = floor - (lineTop + lineHeight);
  float.style.top = `${room >= box.height || room >= lineTop ? lineTop + lineHeight : lineTop - box.height}px`;
  float.style.left = `${Math.max(0, Math.min(anchor.left, document.documentElement.clientWidth - box.width))}px`;
}

addEventListener("scroll", () => scrollY !== openedAt && close(), { passive: true });
addEventListener("resize", close);
document.addEventListener("click", (e) => {
  if (!float.contains(e.target)) close();
});
