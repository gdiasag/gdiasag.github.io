import { statusline } from "./bar.js";
import { buffer, position } from "./pager.js";

const { branch } = JSON.parse(document.getElementById("build").textContent);
const modes = { normal: "NORMAL", command: "COMMAND", visual: "VISUAL" };

const icons = { branch: "", unix: "", markdown: "", help: "󰈙" };

const open = Boolean(buffer?.dataset.filetype);
statusline.hidden = !open;

let mode = "normal";

export function setMode(next) {
  mode = next;
  render();
}

export function render() {
  if (!open) return;
  const { line, total } = position();
  const file = buffer?.dataset.file;
  const filetype = buffer?.dataset.filetype;

  const a = ` ${modes[mode]} `;
  const b = ` ${icons.branch} ${branch} `;
  const x = [" utf-8 ", ` ${icons.unix} `];
  if (filetype) x.push(` <span class="icon-${filetype}">${icons[filetype]}</span> ${filetype} `);
  const y = ` ${line === 1 ? "Top" : line === total ? "Bot" : `${String(Math.floor((100 * line) / total)).padStart(2)}%`} `;
  const z = ` ${String(line).padStart(3)}:1  `;

  const width = (html) => html.replace(/<[^>]+>/g, "").length;
  const xWidth = width(x.join(""));
  let room = columns() - [a, b, y, z].reduce((sum, text) => sum + width(text), 0) - "  [-] ".length;
  const showX = room - xWidth >= (file ?? "").split("/").pop().length;
  if (showX) room -= xWidth;

  statusline.dataset.mode = mode;
  statusline.innerHTML = [
    section("a", a),
    separator("ab"),
    section("b", b),
    separator("bc"),
    section("c", file ? ` ${shorten(file, room)} [-] ` : " [No Name] "),
    `<span class="fill"></span>`,
    ...(showX ? [separator("cx"), section("x", x.join(`<span class="component-separator"></span>`))] : []),
    separator("xy"),
    section("y", y),
    separator("yz"),
    section("z", z),
  ].join("");
}

const section = (name, content) => `<span class="${name}">${content}</span>`;
const separator = (pair) => `<span class="separator ${pair}"></span>`;

function shorten(path, room) {
  const parts = path.split("/");
  let length = path.length;
  for (let i = 0; i < parts.length - 1 && length > room; i++) {
    const short = parts[i].slice(0, parts[i].startsWith(".") ? 2 : 1);
    length -= parts[i].length - short.length;
    parts[i] = short;
  }
  return parts.join("/");
}

function columns() {
  const probe = document.createElement("span");
  probe.textContent = "0".repeat(10);
  statusline.append(probe);
  const width = probe.getBoundingClientRect().width / 10;
  probe.remove();
  return Math.floor(statusline.clientWidth / width);
}

if (open) {
  render();
  addEventListener("scroll", render, { passive: true });
  addEventListener("resize", render);

  new ResizeObserver(render).observe(document.body);
}
