local M = {}
local symbol = require 'symbol'

M.tree = {name = "block", children = {}, errors = {}}

local currentNode = M.tree

local currentParent = {}



function M.createNode(name, value)
	local newNode = {name = name, value = value, children = {}, parent = {}} -- 
	
	return newNode
end

function M.insertNode(parent, node)
	parent = parent or M.tree
	if type(node)~= 'table' then
		node = M.createNode(node)
	end
	node.parent = parent
	table.insert(parent.children,node)
	return node
end

function M.adoptChildren(parent, children)
	if parent and next(children) then
		for _,node in pairs(children) do
			M.insertNode(parent.children, node)
		end
	end
end

function M.makeFamily(op, childrenOps)
	local parent = M.makeNode(op)
	if next(childrenOps) then
		for _,o in pairs(childrenOps) do
			M.insertNode(parent.children, M.makeNode(o))
		end
	end
end

function M.navigateTree(node, indent, show)
	node =  node or M.tree
	indent = indent or ""

	if not node then return end
	
	if node.name == 'block' then symbol.openScope() end
	if node.name == 'dcl' then symbol.enterSymbol(node) end
	if node.name == 'ref' or node.name == 'fcall' then
		local sname = node.children[1].name
		local found, scopeId = symbol.retrieveSymbol(sname)
		if not found then
			--print("INSERTING ERROR"..sname)
			table.insert(M.tree.errors,{scopeId = scopeId, symbolName = sname, msg = "Unexpected use of undeclared variable "..sname.." on line "..node.value.."."})
		end
	end
	if node.name == 'func2' then
	end

	if next(node.children) then
		for _,n in pairs(node.children) do
			if show then print(indent..n.name) end
			
			M.navigateTree(n,indent.."--",show)
		end
	end

	if node.name == 'block' then symbol.closeScope() end
end

return M