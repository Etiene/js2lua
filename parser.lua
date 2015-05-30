local parse = {}

require 'lxsh'
local js = require 'js_lexer'
local util = require 'util'
local ast = require 'ast'

local file = io.open(arg[1],"r")
local src = file:read("*a")
print(src)
io.close(file)

local cursor = 0
local current

local gen_table = {}

-- Gets the scan results, removes comments and white spaces and adds the token in a stream
for kind, text, lnum, cnum in js.gmatch(src) do
	print(string.format('%s: %q (%i:%i)', kind, text, lnum, cnum))
	if kind ~= 'comment' and kind ~= 'whitespace' then
		table.insert(gen_table,{kind = kind, text = text, line = lnum, char = cnum})
	end
end


-- Advance in the stream
function parse.next()
	cursor = cursor+1
	current = gen_table[cursor]
	return current
end

-- Peek
function parse.showNext()
	return gen_table[cursor+1]
end


-- Used for optional semicolons
function parse.maybeExpect(tokenKind)
	local token = parse.showNext()
	if token and tokenKind == token.kind then
		parse.next()
	end
end

-- Predict
function parse.expect(tokenKind, msg, noAdvance)
	msg = msg or ''
	local token = (noAdvance and parse.showNext()) or parse.next()
	if not token then
		msg = msg.."Parsing error. Missing '}'."
		error(msg)
	elseif type(tokenKind) == 'string' then
		if token.kind ~= tokenKind then
			msg = msg.."Parsing error on "..token.line..":"..token.char..". Expecting "..tokenKind.." but got "..token.kind.."."
			error(msg)
		end
	elseif type(tokenKind) == 'table' then
		local match = false
		for _,expected in pairs(tokenKind) do
			if token.kind == expected then
				match = true
			end
		end
		if not match then
			msg = msg.."Parsing error on "..token.line..":"..token.char..". Expecting "..unpack(tokenKind).." but got "..token.kind.."."
			error(msg)
		end
	end
	return token
end

-- Parses list of arguments / parameters for functions
function parse.argList(n,onlyIdentifiers)
	n = n or 0
	local token = parse.showNext()
	if token.kind ~= 'rightpar' then
		n = n + 1
		if onlyIdentifiers then
			parse.expect('identifier')
		else
			parse.expect({'identifier','number','string'})
		end

		token = parse.showNext()
		if token.kind == 'coma' then
			parse.next() -- accept
			parse.argList(n+1,onlyIdentifiers)
		end
	end
	return n
end

function parse.call()
	print('Parsing Function Call')
	parse.expect('leftpar')
	parse.argList()
	parse.expect('rightpar')
end


local function auxExp()
	--while util.in_table({'+','-','*','/','%'},(parse.showNext()).text) do
	while (parse.showNext()).kind == 'operator' do
		parse.next()
		ast.insertNode(node,parse.expression(node))
	end
end

function parse.expression(sibling)
	print("Parsing Expression")
	local node

	local token = parse.showNext()
	if token.kind == 'number' then		-- NUMBER
		local number = ast.createNode(token.text)
		parse.next() -- accept
		node = (((parse.showNext()).kind == 'operator') and parse.expression(number)) or number

	elseif token.kind == 'operator' then
		node = ast.createNode(token.text)
		ast.insertNode(node,sibling)
		parse.next()
		parse.expect({'number','identifier'},nil,true)
		ast.insertNode(node,parse.expression())

	elseif token.kind == 'identifier' then
		parse.expect('identifier','Expression error. ') -- IDENTIFIER
		local var = token.text
		local line = token.line
		local token = parse.showNext()
		if token.kind == 'leftpar' then  -- FUNCTION CALL
			node = ast.createNode('fcall',line)
			ast.insertNode(node,ast.createNode(var))
			parse.call()
		else
			local ref = ast.createNode('ref',line)
			ast.insertNode(ref,var)	
			node = ref				-- NORMAL VAR ACCESS
		end
		node = (((parse.showNext()).kind == 'operator') and parse.expression(node)) or node
	end	
	return node
end

function parse.functionDeclaration(declaration_type, parent) -- 1: var x = function(){}; 2: function x(){}
	print("Parsing Function Declaration")
	parse.expect('function')
	if declaration_type == 2 then
		local token = parse.expect('identifier') -- If type 1 this was declared before and thus not needed
		ast.insertNode(parent,token.text)
	end
	parse.expect('leftpar')
	parse.argList()
	parse.expect('rightpar')
	parse.expect('leftcurly')
	--ast.insertNode(parent,'block')
	parse.stmt(ast.insertNode(parent,'block'))
	parse.expect('rightcurly')
end

function parse._return()
	print("Parsing Function Declaration")
	parse.expect('return')
	local node = ast.createNode('return')
	ast.insertNode(node,parse.expression())
	return node
end

function parse.declaration()
	print("Parsing Declaration")
	local token = parse.expect('var')				-- var x =
	local node = ast.createNode('dcl',token.line)
	local id = parse.expect('identifier')
	ast.insertNode(node,ast.createNode(id.text))

	parse.expect('equal')

	local token = parse.showNext()
	if token.kind == 'function' then -- FUNCTION DECLARATION TYPE 1
		parse.functionDeclaration(1,ast.insertNode(node,'func1'))
	else
		ast.insertNode(node,parse.expression()) -- NORMAL DECLARATION
	end
	return node
end

function parse.stIf(parent)
	print("Parsing If")

	parse.expect('if')		-- if(exp){ stmt* }[else [stIf]* | {}]?
	local thisNode =  ast.createNode('if')
	local node = parent or thisNode

	parse.expect('leftpar')

	ast.insertNode(node,parse.expression())

	parse.expect('rightpar')
	parse.expect('leftcurly')
	parse.stmt(ast.insertNode(node,ast.createNode('block')))
	parse.expect('rightcurly')

	local token = parse.showNext()
	if token and token.kind == 'else' then
		parse.next()
		token = parse.showNext()
		if token.kind == 'if' then
			local elif = parse.stIf(node) -- will parse infinite else ifs :)
		else
			parse.expect('leftcurly')
			parse.stmt(ast.insertNode(node,ast.createNode('block')))
			parse.expect('rightcurly')
		end
	end
	return node
end


function parse.assign(var)
	print("Parsing Assignment") -- x = exp or x++
	local node = ast.createNode('assign')
	ast.insertNode(node,ast.createNode(var))

	local token = parse.showNext()
	if token.text == '=' then
		parse.next()
		ast.insertNode(node,parse.expression()) -- EXPRESSION
	elseif util.in_table({'+=','-=','*=','/=','%='},token.text) then 
		parse.next()
		local op = ast.createNode((token.text):sub(1,1))
		ast.insertNode(op,var)
		ast.insertNode(op,parse.expression()) -- EXPRESSION
		ast.insertNode(node,op)

	elseif util.in_table({'++','--'},token.text) then
		parse.next()
		local op = ast.createNode((token.text):sub(1,1))
		ast.insertNode(node,op)
		ast.insertNode(op,var)
		ast.insertNode(op,1)

	else
		error("Parsing error on "..token.line..":"..token.char..". Expected operator, got "..token.kind)
	end
	return node
end

function parse._while()
	print("Parsing While") 
	
	parse.expect('while')
	local node = ast.createNode('while')

	parse.expect('leftpar')
	ast.insertNode(node,parse.expression())
	parse.expect('rightpar')
	parse.expect('leftcurly')
	parse.stmt(ast.insertNode(node,ast.createNode('block')))
	parse.expect('rightcurly')

	return node
end

function parse.stmt(parent)

	print("Parsing Statement")
	
	local token = parse.showNext()
	if token then
		local node = ast.createNode('[empty]')

		-- DECLARATION
		if token.kind == 'var' then
			node = parse.declaration()
			parse.maybeExpect('semicolon')

		-- IF
		elseif token.kind == 'if' then
			node = parse.stIf()
			parse.maybeExpect('semicolon')

		elseif token.kind == 'identifier' then
			local var = token.text
			parse.next() -- accept
			token = parse.showNext()

			-- FUNCTION CALL
			if token.kind == 'leftpar' then
				node = ast.createNode('fcall',token.line)
				parse.call()
				ast.insertNode(node,ast.createNode(var))
			-- ASSIGNMENT
			else
				node = parse.assign(var)
			end

			parse.maybeExpect('semicolon')

		-- FUNCTION DECLARATION TYPE 2 -> function x(){}
		elseif token.kind == 'function' then
			node = ast.createNode('dcl',token.line)
			parse.functionDeclaration(2,ast.insertNode(node,'func2'))
			parse.maybeExpect('semicolon')

		-- WHILE
		elseif token.kind == 'while' then
			node = parse._while()
			parse.maybeExpect('semicolon')

		-- RETURN
		elseif token.kind == 'return' then
			node = parse._return()
			parse.maybeExpect('semicolon')

		 -- TODO: for, etc
		elseif token.kind ~= 'rightcurly' then
			error("Parsing error on "..token.line..":"..token.char..". Expected ?, got "..token.kind)
		end

		ast.insertNode(parent,node)
		if parse.showNext() and (parse.showNext()).kind ~= 'rightcurly' then
			parse.stmt(parent)
		end
	end
end

-- begin
parse.stmt()

ast.navigateTree(nil,nil,true) -- run through the tree and insert symbols

if next(ast.tree.errors) then
	for _,e in pairs(ast.tree.errors) do
		error(e.msg)
	end
end

--ast.navigateTree(nil,nil,true,true) -- run through the tree again and verify symbols / make modifications in the tree


