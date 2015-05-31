local M = {}
local src = ""

function M.exp(node)
	node.visited = 1
	local str = ""
	if node.name == 'ref' or node.name == 'fcall' then
		node.children[1].visited = 1
		str = node.children[1].name

	elseif next(node.children) then
		local leftChild = M.exp(node.children[1])
		local rightChild = M.exp(node.children[2])
		str = str.. leftChild.." "..node.name.." "..rightChild 
	else
		str = node.name
	end

	return str
end

function M.func(node)
	node.visited = 1
	node.children[1].visited = 1
	local str
	if node.name =='func1' then --local x = f
		str = "local "..node.children[1].name.." = function( "
	else
		str = "function "..node.children[1].name.."( "
	end
	local parms = {}
	node.children[2].visited = 1
	for _,n in pairs(node.children[2].children) do
		n.visited = 1
		table.insert(parms,n.name)
	end
	str = str..table.concat(parms," , ").." )\n"

	node.children[3].visited = 1
	str = str..M.code(node.children[3])

	return str.."end\n"
end

function M.dcl(node)
	node.visited = 1
	if node.children[1].name == 'func1' or node.children[1].name == 'func2' then
		return M.func(node.children[1])
	end
	node.children[1].visited = 1
	local str = "local "..node.children[1].name
	if #node.children > 1 then
		str = str.." = "..M.exp(node.children[2])
	end
	return str..'\n'
end

function M.fcall(node)
	node.visited = 1
	node.children[1].visited = 1
	local str = node.children[1].name.."( "
	node.children[2].visited = 1
	local args = {}
	for _,n in pairs(node.children[2].children) do
		n.visited = 1
		local arg
		if n.name == 'fcall' then
			arg = M.fcall(n)
		elseif n.name == 'ref' then
			n.children[1].visited = 1
			arg = n.children[1].name
		else
			arg = n.name
		end
		table.insert(args,arg)
	end
	return str..table.concat(args," , ").." )"
end

function M.assign(node)
	node.visited = 1
	node.children[1].visited = 1
	return node.children[1].name.." = "..M.exp(node.children[2])..'\n'
end

function M._if(node)
	node.visited = 1
	local str = "if "..M.exp(node.children[1]).." then\n"

	node.children[2].visited = 1
	str = str..M.code(node.children[2])

	local cursor = 3
	--search elifs
	while cursor + 1 <= #node.children do
		node.children[cursor].visited = 1
		str = str.."elseif "..M.exp(node.children[cursor]).." then\n"
		node.children[cursor+1].visited = 1
		str = str..M.code(node.children[cursor+1])
		cursor = cursor + 2
	end
	if cursor <= #node.children then
		node.children[cursor].visited = 1
		str = str.."else\n"..M.code(node.children[cursor])
	end
	return str.."end\n"
end

function M.code(node)
	local src = src or ""
	if node then

		if node.name == 'dcl' then src = src..M.dcl(node) end
		if node.name == 'fcall' then src = src..M.fcall(node)..'\n' end
		if node.name == 'assign' then src = src..M.assign(node) end
		if node.name == 'if' then src = src..M._if(node) end

		if next(node.children) then
			for _,n in pairs(node.children) do
				if not n.visited then
				  src = src.. M.code(n)
				end
			end
		end
	end
	return src
end

return M