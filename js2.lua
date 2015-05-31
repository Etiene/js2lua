require 'lxsh'
local parser = require "src.parser"
local generate = require "src.generator"

local file = io.open(arg[1],"r")
local src = file:read("*a")
print(src)
io.close(file)

local ast = parser.parse(src)

ast.navigateTree(nil,nil,false) -- run through the tree and inserts symbols / recovers from error 
ast.navigateTree(nil,nil,true) -- run through the tree again just to show modified tree.

-- Semantic error (undeclared things)
if next(ast.tree.errors) then
	for _,e in pairs(ast.tree.errors) do
		error(e.msg)
	end
end

local new_src = generate.code(ast.tree,true)

--print(new_src)
file = io.open("out.lua","w")
file:write(new_src)
io.close(file)
