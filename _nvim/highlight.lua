local name = arg[1]
if not name or name == "" then
	io.stderr:write("Usage: nvim --clean --headless -l highlight.lua <language> < code\n")
	vim.cmd("cquit 1")
end

local code = io.read("*a") or ""
if code == "" then
	io.write(vim.json.encode({}))
	os.exit(0)
end

-- Tags in plain Neovim, never colors.
local IGNORED_CAPTURES = {
	spell = true,
	nospell = true,
	conceal = true,
	none = true,
}

--- Resolves string parser for candidate language, filetype, or extension
---@param language string
---@return vim.treesitter.LanguageTree?
local function parser_for(language)
	local filetype = vim.filetype.match({ filename = "code." .. language })
	local candidates = {
		language,
		vim.treesitter.language.get_lang(language),
		filetype and vim.treesitter.language.get_lang(filetype),
	}

	for _, candidate in ipairs(candidates) do
		if candidate then
			local ok, parser = pcall(vim.treesitter.get_string_parser, code, candidate)
			if ok and parser then
				return parser
			end
		end
	end
	return nil
end

local spans = {}
local parser = parser_for(name)

if parser then
	parser:parse(true)
	parser:for_each_tree(function(tree, language_tree)
		local lang = language_tree:lang()
		local query = vim.treesitter.get_query(lang, "highlights")
			or pcall(vim.treesitter.query.get, lang, "highlights") and vim.treesitter.query.get(lang, "highlights")

		if not query then
			return
		end

		for id, node, metadata in query:iter_captures(tree:root(), code) do
			local capture = query.captures[id]
			if not capture:match("^_") and not IGNORED_CAPTURES[capture] then
				local _, _, from = node:start()
				local _, _, to = node:end_()

				-- Priority extraction handling
				local prio = metadata.priority
				if not prio and metadata[id] then
					prio = metadata[id].priority
				end

				spans[#spans + 1] = {
					from = from,
					to = to,
					capture = capture,
					priority = tonumber(prio) or 100,
					order = #spans + 1,
				}
			end
		end
	end)
end

-- Later captures of the same priority are drawn on top, matching Neovim.
table.sort(spans, function(a, b)
	if a.priority ~= b.priority then
		return a.priority < b.priority
	end
	return a.order < b.order
end)

-- Track capture stacks per byte offset
local stacks = {}
for _, span in ipairs(spans) do
	for byte = span.from, span.to - 1 do
		local stack = stacks[byte]
		if not stack then
			stack = {}
			stacks[byte] = stack
		end
		if stack[#stack] ~= span.capture then
			stack[#stack + 1] = span.capture
		end
	end
end

--- Get space-delimited capture string at byte index
---@param byte integer
---@return string
local function key(byte)
	return stacks[byte] and table.concat(stacks[byte], " ") or ""
end

local runs = {}
local from = 0
local code_len = #code

for byte = 1, code_len do
	if byte == code_len or key(byte) ~= key(from) then
		runs[#runs + 1] = { code:sub(from + 1, byte), key(from) }
		from = byte
	end
end

io.write(vim.json.encode(runs))
