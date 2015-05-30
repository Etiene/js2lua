local M = {}

M.tree = {name = "Program", children = {}}

local currentNode = M.tree

local currentParent = {}



function M.createNode(name, value)
	local newNode = {name = name, value = value, children = {}, parent = {}} -- 
	
	--currentNode = newNode
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

function M.navigateTree(subtree, indent, show, map)
	subtree =  subtree or M.tree
	indent = indent or ""
	if next(subtree.children) then
		for _,node in pairs(subtree.children) do
			if show then print(indent..node.name) end
			M.navigateTree(node,indent.."--",show,map)
		end
	end
end

return M