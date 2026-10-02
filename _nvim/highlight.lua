local code = io.read("a")
local name = arg[1]

local ignored = { spell = true, nospell = true, conceal = true, none = true }

local function parser_for(language)
	local filetype = vim.filetype.match({ filename = "code." .. language })
	local candidates = {
		language,
		vim.treesitter.language.get_lang(language),
		filetype and vim.treesitter.language.get_lang(filetype),
	}
	for _, candidate in ipairs(candidates) do
		local ok, parser = pcall(vim.treesitter.get_string_parser, code, candidate)
		if ok and parser then
			return parser
		end
	end
end

local spans = {}
local parser = parser_for(name)
if parser then
	parser:parse(true)
	parser:for_each_tree(function(tree, language_tree)
		local query = vim.treesitter.query.get(language_tree:lang(), "highlights")
		if not query then
			return
		end
		for id, node, metadata in query:iter_captures(tree:root(), code) do
			local capture = query.captures[id]
			if not capture:match("^_") and not ignored[capture] then
				local _, _, from = node:start()
				local _, _, to = node:end_()
				local priority = tonumber(metadata.priority or metadata[id] and metadata[id].priority) or 100
				table.insert(spans, { from = from, to = to, capture = capture, priority = priority, order = #spans })
				-- What 'conceallevel' would hide, for the page to decide.
				if metadata.conceal or metadata[id] and metadata[id].conceal then
					table.insert(spans, { from = from, to = to, capture = "concealed", priority = priority, order = #spans })
				end
			end
		end
	end)
end

table.sort(spans, function(a, b)
	if a.priority ~= b.priority then
		return a.priority < b.priority
	end
	return a.order < b.order
end)

local stacks = {}
for _, span in ipairs(spans) do
	for byte = span.from, span.to - 1 do
		local stack = stacks[byte] or {}
		if stack[#stack] ~= span.capture then
			table.insert(stack, span.capture)
		end
		stacks[byte] = stack
	end
end

local function key(byte)
	return table.concat(stacks[byte] or {}, " ")
end

local runs, from = {}, 0
for byte = 1, #code do
	if byte == #code or key(byte) ~= key(from) then
		table.insert(runs, { code:sub(from + 1, byte), key(from) })
		from = byte
	end
end

io.write(vim.json.encode(runs))
