local theme, colorscheme, background, lualine_theme, setup = arg[1], arg[2], arg[3], arg[4], arg[5]

if not (theme and colorscheme and background and lualine_theme) then
	io.stderr:write(
		"Usage: nvim --clean --headless -l theme.lua <theme> <colorscheme> <background> <lualine_theme> [setup]\n"
	)
	vim.cmd("cquit 1")
end

vim.o.termguicolors = true
vim.o.background = background

if setup and setup ~= "" then
	vim.cmd(setup)
end

vim.cmd.colorscheme(colorscheme)

require("nvim-web-devicons").setup()
require("lualine").setup({
	options = {
		theme = lualine_theme,
		section_separators = "",
		component_separators = "",
	},
})

-- Core editor highlight groups to export
local EDITOR_GROUPS = {
	"Normal",
	"Visual",
	"Cursor",
	"LineNr",
	"CursorLineNr",
	"CursorLine",
	"Search",
	"CurSearch",
	"Pmenu",
	"PmenuSel",
	"NormalFloat",
	"FloatBorder",
	"ErrorMsg",
	"WarningMsg",
	"DevIconMd",
	"Directory",
}

-- ANSI Color Names mapping
local ANSI_NAMES = {
	"black",
	"red",
	"green",
	"yellow",
	"blue",
	"magenta",
	"cyan",
	"white",
}

--- Format color integer to CSS hex string
---@param color? integer
---@return string
local function hex(color)
	return color and ("#%06x"):format(color) or ""
end

--- Resolve full highlight attributes for a group
---@param group string
---@return vim.api.keyset.hl_info
local function resolve(group)
	local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
	if not next(hl) then
		local id = vim.fn.hlID(group)
		if id ~= 0 then
			hl = vim.api.nvim_get_hl(0, { id = vim.fn.synIDtrans(id), link = false })
		end
	end
	return hl
end

local normal = resolve("Normal")

-- Collect all valid Treesitter captures available in runtime parsers
local captures_set = {}
for _, file in ipairs(vim.api.nvim_get_runtime_file("parser/*.so", true)) do
	local lang = vim.fn.fnamemodify(file, ":t:r")
	local ok, query = pcall(vim.treesitter.query.get, lang, "highlights")
	if ok and query then
		for _, capture in ipairs(query.captures) do
			if not capture:match("^_") then
				captures_set[capture] = true
			end
		end
	end
end

local captures = vim.tbl_keys(captures_set)
table.sort(captures)

--- Build CSS declaration rules for a highlight entry
---@param hl vim.api.keyset.hl_info
---@return string[]
local function declarations(hl)
	local css = {}
	if hl.fg then
		css[#css + 1] = "color: " .. hex(hl.fg)
	end
	if hl.bg and hl.bg ~= normal.bg then
		css[#css + 1] = "background-color: " .. hex(hl.bg)
	end
	if hl.bold then
		css[#css + 1] = "font-weight: bold"
	end
	if hl.italic then
		css[#css + 1] = "font-style: italic"
	end

	local decorations = {}
	if hl.underline or hl.undercurl then
		decorations[#decorations + 1] = "underline"
	end
	if hl.strikethrough then
		decorations[#decorations + 1] = "line-through"
	end
	if #decorations > 0 then
		css[#css + 1] = "text-decoration: " .. table.concat(decorations, " ")
	end

	return css
end

--- Extract FG and BG taking `reverse` attribute into account
---@param hl vim.api.keyset.hl_info
---@return integer?, integer?
local function colors(hl)
	if hl.reverse then
		return hl.bg or normal.bg, hl.fg or normal.fg
	end
	return hl.fg, hl.bg
end

--- Resolves Lualine section colors with fallbacks
---@param name string
---@param mode string
---@return vim.api.keyset.hl_info
local function section(name, mode)
	local hl = vim.api.nvim_get_hl(0, { name = ("lualine_%s_%s"):format(name, mode), link = false })
	if next(hl) then
		return hl
	end

	local fallback_section = ({ x = "c", y = "b", z = "a" })[name]
	if fallback_section then
		return section(fallback_section, mode)
	end

	return section(name, "normal")
end

--- Convert separator string to a CSS quoted string or unicode escape
---@param text string
---@return string
local function css_string(text)
	if text == "" then
		return '""'
	end
	return ('"\\%x"'):format(vim.fn.char2nr(text))
end

--- Export Lualine mode styles
---@param mode string
---@return string
local function lualine_css(mode)
	local separators = require("lualine").get_config().options.section_separators
	local vars = {}
	local sections = {}

	for _, name in ipairs({ "a", "b", "c", "x", "y", "z" }) do
		local hl = section(name, mode)
		sections[name] = hl
		vars[#vars + 1] = ("--%s-fg: %s; --%s-bg: %s;"):format(name, hex(hl.fg), name, hex(hl.bg))
		if hl.bold then
			vars[#vars + 1] = ("--%s-weight: bold;"):format(name)
		end
	end

	local transitions = {
		{ "a", "b", "left" },
		{ "b", "c", "left" },
		{ "c", "x", "right" },
		{ "x", "y", "right" },
		{ "y", "z", "right" },
	}

	for _, pair in ipairs(transitions) do
		local from, to, side = table.unpack(pair)
		local drawn = sections[from].bg ~= sections[to].bg
		local sep_val = drawn and css_string(separators[side]) or '""'
		vars[#vars + 1] = ("--%s%s: %s;"):format(from, to, sep_val)
	end

	return ('  .lualine[data-mode="%s"] { %s }'):format(mode, table.concat(vars, " "))
end

--- Extract foreground color for highlight group
---@param group string
---@return string?
local function fg(group)
	local color = resolve(group).fg
	return color and hex(color)
end

-- Fallback mapping derived from Neovim diagnostic and syntax highlights
local derived_ansi = {
	[0] = hex(normal.bg),
	fg("DiagnosticError"),
	fg("DiagnosticOk"),
	fg("DiagnosticWarn"),
	fg("DiagnosticInfo"),
	fg("Keyword"),
	fg("DiagnosticHint"),
	hex(normal.fg),
	fg("Comment"),
}

--- Lookup terminal ANSI color hex value
---@param i integer
---@return string
local function ansi(i)
	local color = vim.g["terminal_color_" .. i]
	if type(color) == "string" and color:match("^#%x%x%x%x%x%x$") then
		return color:lower()
	end
	return derived_ansi[i] or derived_ansi[i - 8] or hex(normal.fg)
end

-- Generate CSS Output
local out = {
	("// %s, generated by _nvim/theme.lua"):format(theme),
	('[data-theme="%s"] {'):format(theme),
}

for i, name in ipairs(ANSI_NAMES) do
	out[#out + 1] = ("  --%s: %s; --bright-%s: %s;"):format(name, ansi(i - 1), name, ansi(i + 7))
end

for _, group in ipairs(EDITOR_GROUPS) do
	local group_fg, group_bg = colors(resolve(group))
	if group_fg then
		out[#out + 1] = ("  --%s-fg: %s;"):format(group, hex(group_fg))
	end
	if group_bg then
		out[#out + 1] = ("  --%s-bg: %s;"):format(group, hex(group_bg))
	end
end

local component_sep = require("lualine").get_config().options.component_separators
out[#out + 1] = ("  --component-separator: %s;"):format(css_string(component_sep.right))

for _, mode in ipairs({ "normal", "command", "visual" }) do
	out[#out + 1] = lualine_css(mode)
end

out[#out + 1] = "  .highlight {"
for _, capture in ipairs(captures) do
	local css = declarations(resolve("@" .. capture))
	if #css > 0 then
		out[#out + 1] = ("    .%s { %s; }"):format(capture:gsub("%.", "-"), table.concat(css, "; "))
	end
end
out[#out + 1] = "  }"
out[#out + 1] = "}"

io.write(table.concat(out, "\n") .. "\n")
