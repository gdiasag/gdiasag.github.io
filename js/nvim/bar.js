export const bar = document.createElement("div");
bar.className = "vim-bar";
bar.innerHTML = `
  <ul class="vim-menu" hidden></ul>
  <div class="lualine" data-mode="normal"></div>
  <p class="vim-line" aria-live="polite"></p>
  <form class="vim-prompt" hidden>
    <label></label><input autocomplete="off" autocapitalize="off" spellcheck="false" aria-label="command line">
  </form>`;
document.body.append(bar);

export const statusline = bar.querySelector(".lualine");
const menu = bar.querySelector(".vim-menu");
const line = bar.querySelector(".vim-line");
const form = bar.querySelector(".vim-prompt");
const label = form.querySelector("label");
const input = form.querySelector("input");

export function message(text, kind = "") {
  line.textContent = text;
  line.className = `vim-line ${kind}`;
}

export function clearMessage() {
  message("");
}

export function prompt(char, { complete, live } = {}) {
  const past = load(char);
  let back = past.length;
  let completion = null;

  line.hidden = true;
  form.hidden = false;
  label.textContent = char;
  input.value = "";
  input.focus();

  const cycle = (step) => {
    if (!completion) {
      const { start, items } = complete(input.value);
      if (items.length === 0) return;
      completion = { start, items, index: step > 0 ? 0 : items.length - 1 };
      menu.innerHTML = items.length > 1 ? items.map((item) => `<li>${item}</li>`).join("") : "";
      menu.style.left = `${start + 1}ch`;
      menu.hidden = items.length === 1;
    } else {
      completion.index = (completion.index + step + completion.items.length) % completion.items.length;
    }
    const { start, items, index } = completion;
    input.value = input.value.slice(0, start) + items[index];
    [...menu.children].forEach((item, i) => item.classList.toggle("selected", i === index));
    if (items.length === 1) completion = null;
    live?.(input.value);
  };

  const recall = (step) => {
    back = Math.min(Math.max(back + step, 0), past.length);
    input.value = past[back] ?? "";
    live?.(input.value);
  };

  return new Promise((resolve) => {
    const finish = (text) => {
      form.onsubmit = input.onkeydown = input.oninput = input.onblur = null;
      form.hidden = menu.hidden = true;
      line.hidden = false;
      input.blur();
      if (text) save(char, [...past, text]);
      resolve(text);
    };

    form.onsubmit = (e) => {
      e.preventDefault();
      finish(input.value);
    };
    input.onblur = () => finish(null);
    input.oninput = () => {
      completion = null;
      menu.hidden = true;
      live?.(input.value);
    };
    input.onkeydown = (e) => {
      const handlers = {
        Escape: () => finish(null),
        Backspace: () => input.value === "" && finish(null),
        Tab: () => complete && cycle(e.shiftKey ? -1 : 1),
        ArrowUp: () => recall(-1),
        ArrowDown: () => recall(1),
      };
      if (!handlers[e.key]) return;
      if (e.key !== "Backspace" || input.value === "") e.preventDefault();
      handlers[e.key]();
    };
  });
}

function load(char) {
  try {
    return JSON.parse(sessionStorage.getItem(`vim-history${char}`)) ?? [];
  } catch {
    return [];
  }
}

function save(char, history) {
  try {
    sessionStorage.setItem(`vim-history${char}`, JSON.stringify(history.slice(-50)));
  } catch {}
}
