local reserved = {
	"break",
	"do",
	"instanceof",
	"typeof",
	"case",
	"else",
	"new",
	"var",
	"catch",
	"finally",
	"return",
	"void",
	"continue",
	"for",
	"switch",
	"while",
	"debugger",
	"function",
	"this",
	"with",
	"default",
	"if",
	"throw",
	"delete",
	"in",
	"try"
}

local r = {}
-- r.break = "break" etc. 
-- might be useful (or not)
for _,v in pairs(reserved) do
	r[v] = v
end

local tokens = {
	opencurly = "{",	
	closecurly = "}",
	openpar = "%(",
	closepar = "%)",
	opensquare = "%[",
	closesquare = "%]",
	dot = "%.",
	semicolon = ";",
	coma = ",",
	st = "<",
	gt = ">",
	soet = "<=",
	goet = ">=",
	equal = "==",
	different = "!=",
	equalvalueandtype = "===",
	differentvalueortype = "!==",
	plus = "%+",
	minus = "%-",
	multiply = "%*",
	modulo = "%%",
	plusplus = "++",
	minusminus = "--",
	shiftleft = "<<",
	shiftright = ">>",
	binshiftright = ">>>",
	binand = "&",
	binor = "|",
	xor = "%^",
	_not = "!",
	binnot = "~",
	_and = "&&",
	_or = "||",
	ternary = "%?",
	ternaryseparator = ":",
	assign = "=",
	addassign = "+=",
	subtractassign = "-=",
	multiplyassign = "*=",
	moduloassign = "%=",
	shiftleftassign = "<<=",
	shiftrightassign = ">>=",
	binshiftrightassign = ">>>=",
	andassign = "&=",
	orassign = "|=",
	xorassign = "^=",
	-- OTHERS
	whitespace = '^%s+',
	identifier = '^[%a][%w]*',
	string = '%"%w+%"',

}


local file = io.open(arg[1],"r")
local src = file:read("*a")
print(src)
io.close(file)
