import { message } from "./bar.js";
import { goToLine, quit } from "./pager.js";
import { clear as nohlsearch } from "./search.js";

const build = JSON.parse(document.getElementById("build").textContent);

const readonly = (bang) =>
  message(bang ? "E212: Can't open file for writing" : "E45: 'readonly' option is set (add ! to override)", "error");

const commands = {
  colorscheme: ["colo", colorscheme],
  edit: ["e", edit],
  help: ["h", help],
  nohlsearch: ["noh", nohlsearch],
  quit: ["q", quit],
  set: ["se", set],
  version: ["ve", version],
  write: ["w", (_, bang) => readonly(bang)],
  wq: ["wq", (_, bang) => readonly(bang)],
  xit: ["x", quit],
};

const options = { number: "nu", cursorline: "cul", wrap: "wrap" };
const defaults = { number: false, cursorline: false, wrap: true };
const values = { ...defaults, ...load() };
apply();

export function run(line) {
  previewing = null;
  const [, name, bang, argument] = line?.trim().match(/^(\w*)(!?)\s*(.*)$/) ?? [];
  if (!line?.trim()) return;
  if (/^\d+$/.test(name)) return goToLine(Number(name));

  const command = Object.entries(commands).find(
    ([full, [short]]) => full.startsWith(name) && name.length >= short.length,
  );
  if (!command) return message(`E492: Not an editor command: ${line.trim()}`, "error");
  command[1][1](argument, bang === "!");
}

export function complete(text) {
  const [, before, word] = text.match(/^(.*?)(\S*)$/);
  const [name] = before.trim().split(/\s+/);
  const matching = (items) => items.filter((item) => item.startsWith(word));

  if (!before.trim()) return { start: before.length, items: matching(Object.keys(commands)) };
  if (expands(name, "colorscheme")) return { start: before.length, items: matching(window.colorscheme.names) };
  if (expands(name, "edit")) {
    const next = Object.keys(files).map((file) => file.slice(0, file.indexOf("/", word.length) + 1 || undefined));
    return { start: before.length, items: matching([...new Set(next)].sort()).filter((item) => item !== word) };
  }
  if (expands(name, "set")) {
    const names = Object.keys(options);
    return { start: before.length, items: matching([...names, ...names.map((o) => `no${o}`)]) };
  }
  if (expands(name, "help")) return { start: before.length, items: matching(tags) };
  return { start: 0, items: [] };
}

const expands = (name, full) => full.startsWith(name) && name.length >= commands[full][0].length;

let previewing = null;

export function preview(text) {
  const [, name, argument] = text.trim().match(/^(\w+)\s+(\S+)$/) ?? [];
  if (name && expands(name, "colorscheme") && window.colorscheme.names.includes(argument)) {
    previewing = argument;
    window.colorscheme.show(argument);
  } else cancel();
}

export function cancel() {
  if (previewing) window.colorscheme.show(window.colorscheme.chosen());
  previewing = null;
}

const helpfile = "/quickref";

let files = {};
let tags = [];
let fetching = null;

export const prefetch = () =>
  (fetching ??= Promise.all([
    fetch("/files.json").then((response) => response.json()),
    fetch(helpfile).then((response) => response.text()),
  ])
    .then(([listed, help]) => {
      files = listed;
      tags = [...new DOMParser().parseFromString(help, "text/html").querySelectorAll(".label[id]")].map((t) => t.id);
    })
    .catch(() => (fetching = null)));

async function edit(name) {
  if (!name) return location.reload();
  await prefetch();
  const path = name.replace(/^\.?\//, "");
  const url = files[path] ?? files[`${path}/`];
  if (!url) return message(`E484: Can't open file ${name}`, "error");
  location.href = url;
}

function colorscheme(name) {
  if (!name) return message(window.colorscheme.current());
  if (!window.colorscheme.names.includes(name)) return message(`E185: Cannot find color scheme '${name}'`, "error");
  window.colorscheme.apply(name);
}

async function help(subject) {
  if (!subject) return (location.href = helpfile);
  await prefetch();
  const tag = helptag(subject);
  if (!tag) return message(`E149: Sorry, no help for ${subject}`, "error");
  location.href = `${helpfile}#${tag}`;
}

// The tag for {subject}: itself, or the option or command it names.
function helptag(subject) {
  const name = subject.replace(/^:/, "");
  const command = Object.keys(commands).find((full) => expands(name, full));
  return [subject, `'${subject}'`, command && `:${commands[command][0]}`].find((tag) => tags.includes(tag));
}

function version() {
  const date = new Date(build.time).toDateString().slice(4);
  message(
    `gustavos.terminal ${build.revision.slice(0, 7)} (${build.branch}), built ${date}` +
      ` with Jekyll ${build.jekyll}, Ruby ${build.ruby} and Neovim ${build.neovim}`,
  );
}

function set(argument) {
  if (!argument) {
    const changed = Object.keys(options).filter((o) => values[o] !== defaults[o]);
    return message(changed.map((o) => (values[o] ? `  ${o}` : `no${o}`)).join("  "));
  }
  for (const word of argument.split(/\s+/)) {
    const [, prefix, name, suffix] = word.match(/^(no|inv)?(\w+)([!?]?)$/) ?? [];
    const option = Object.keys(options).find((o) => o === name || options[o] === name);
    if (!option) return message(`E518: Unknown option: ${word}`, "error");
    if (suffix === "?") return message(values[option] ? `  ${option}` : `no${option}`);
    values[option] = prefix === "inv" || suffix === "!" ? !values[option] : prefix !== "no";
  }
  apply();
  save();
}

function apply() {
  const root = document.documentElement.classList;
  root.toggle("number", values.number);
  root.toggle("cursorline", values.cursorline);
  root.toggle("nowrap", !values.wrap);
}

function load() {
  try {
    return JSON.parse(localStorage.getItem("vim-options")) ?? {};
  } catch {
    return {};
  }
}

function save() {
  try {
    localStorage.setItem("vim-options", JSON.stringify(values));
  } catch {}
}
