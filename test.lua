require 'lxsh'
local js = require 'js_lexer'
local file = io.open(arg[1],"r")
local src = file:read("*a")
print(src)
io.close(file)


for kind, text, lnum, cnum in js.gmatch(src) do
	print(string.format('%s: %q (%i:%i)', kind, text, lnum, cnum))
end
