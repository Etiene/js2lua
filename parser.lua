local parse = {}

require 'lxsh'
local js = require 'js_lexer'
local util = require 'util'

local file = io.open(arg[1],"r")
local src = file:read("*a")
print(src)
io.close(file)

local cursor = 0
local current

--local generated_code = ""

local gen_table = {}
--local tree = {}

local declaration_scope = {}

for kind, text, lnum, cnum in js.gmatch(src) do
	print(string.format('%s: %q (%i:%i)', kind, text, lnum, cnum))
	if kind ~= 'comment' and kind ~= 'whitespace' then
		table.insert(gen_table,{kind = kind, text = text, line = lnum, char = cnum})
	end
end

function parse.next()
	cursor = cursor+1
	current = gen_table[cursor]
	return current
end

function parse.showNext()
	return gen_table[cursor+1]
end

function parse.maybeExpect(tokenKind)
	local token = parse.showNext()
	if token and tokenKind == token.kind then
		parse.next()
	end
end

function parse.expect(tokenKind, msg)
	msg = msg or ''
	local token = parse.next()
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
			msg = msg.."Parsing error on "..token.line..":"..token.char..". Expecting "..table.unpack(tokenKind).." but got "..token.kind.."."
			error(msg)
		end
	end
	return token
end

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
		parse.expression()
	end
end

function parse.expression()
	print("Parsing Expression")
	local token = parse.showNext()
	if token.kind == 'number' then		-- NUMBER
		parse.next() -- accept
		auxExp()
	else
		parse.expect('identifier','Expression error. ') -- IDENTIFIER
		local token = parse.showNext()
		if token.kind == 'leftpar' then  -- FUNCTION CALL
			parse.call()
		else
			auxExp()					-- NORMAL VAR ACCESS
		end
	end	
end

function parse.functionDeclaration(declaration_type) -- 1: var x = function(){}; 2: function x(){}
	print("Parsing Function Declaration")
	parse.expect('function')
	if declaration_type == 2 then
		parse.expect('identifier') -- If type 1 this was declared before and thus not needed
	end
	parse.expect('leftpar')
	parse.argList()
	parse.expect('rightpar')
	parse.expect('leftcurly')
	parse.stmt()
	parse.expect('rightcurly')
end

function parse.declaration()
	print("Parsing Declaration")
	parse.expect('var')				-- var x =
	parse.expect('identifier')
	parse.expect('equal')
	local token = parse.showNext()
	if token.kind == 'function' then -- FUNCTION DECLARATION TYPE 1
		parse.functionDeclaration(1)
	else
		parse.expression() -- NORMAL DECLARATION
	end
end

function parse.stIf()
	print("Parsing If")
	parse.expect('if')		-- if(exp){ stmt* }[else [stIf]* | {}]?
	parse.expect('leftpar')
	parse.expression()
	parse.expect('rightpar')
	parse.expect('leftcurly')
	parse.stmt()
	parse.expect('rightcurly')

	local token = parse.showNext()
	if token and token.kind == 'else' then
		parse.next()
		token = parse.showNext()
		if token.kind == 'if' then
			parse.stIf() -- will parse infinite else ifs :)
		else
			parse.expect('leftcurly')
			parse.stmt()
			parse.expect('rightcurly')
		end
	end
end


function parse.assign()
	print("Parsing Assignment") -- x = exp or x++
	
	local token = parse.showNext()
	if util.in_table({'=','+=','-=','*=','/=','%='},token.text) then 
		parse.next()
		parse.expression()

	elseif util.in_table({'++','--'},token.text) then
		parse.next()

	else
		error("Parsing error on "..token.line..":"..token.char..". Expected operator, got "..token.kind)
	end
end

function parse._while()
	print("Parsing While") 
	parse.expect('while')
	parse.expect('leftpar')
	parse.expression()
	parse.expect('rightpar')
	parse.expect('leftcurly')
	parse.stmt()
	parse.expect('rightcurly')
end

function parse.stmt()
	print("Parsing Statement")
	local token = parse.showNext()
	-- DECLARATION
	if token.kind == 'var' then
		parse.declaration()
		parse.maybeExpect('semicolon')

	-- IF
	elseif token.kind == 'if' then
		parse.stIf()
		parse.maybeExpect('semicolon')

	elseif token.kind == 'identifier' then
		parse.next() -- accept

		token = parse.showNext()

		-- FUNCTION CALL
		if token.kind == 'leftpar' then
			parse.call()
			
		-- ASSIGNMENT
		else
			parse.assign()
		end

		parse.maybeExpect('semicolon')

	-- FUNCTION DECLARATION TYPE 2 -> function x(){}
	elseif token.kind == 'function' then
		parse.functionDeclaration(2)
		parse.maybeExpect('semicolon')

	-- WHILE
	elseif token.kind == 'while' then
		parse._while()
		parse.maybeExpect('semicolon')

	 -- TODO: for, etc
	elseif token.kind ~= 'rightcurly' then
		error("Parsing error on "..token.line..":"..token.char..". Expected ?, got "..token.kind)
	end

	if parse.showNext() and (parse.showNext()).kind ~= 'rightcurly' then
		parse.stmt()
	end
end


parse.stmt()
