local M = {}

local symbolTable = {}

local currentScope
local idcount = 0

function M.openScope()
	idcount = idcount+1

	currentScope = {outerScope = currentScope, id = idcount, symbols = {}}
	table.insert(symbolTable,currentScope)
	--print("OPEN SCOPE"..currentScope.id.." outer:"..(currentScope.outerScope and currentScope.outerScope.id or ""))

end

function M.closeScope()
	--print "CLOSE SCOPE"
	currentScope = currentScope.outerScope
end

function M.enterSymbol(node)
	local stype = "var"
	local symbol = node.children[1].name
	if symbol == 'func1' or symbol == 'func2' then
		stype = symbol
		symbol = (node.children[1]).children[1].name
	end
	table.insert(currentScope.symbols,{symbol = symbol, stype = stype})

	--print ("ENTER SYMBOL"..stype..symbol)
end

function M.retrieveSymbol(symbol)
	local scopeCursor = currentScope
	local found = false
	while scopeCursor ~= nil do
		if next(scopeCursor.symbols) then
			for _,s in pairs(scopeCursor.symbols) do
				--print("SYMBOLNAME"..s.symbol..symbol..scopeCursor.id)
				if s.symbol == symbol then
					found = true
				end
			end
		end
		scopeCursor = scopeCursor.outerScope
	end
	return found
end

return M
